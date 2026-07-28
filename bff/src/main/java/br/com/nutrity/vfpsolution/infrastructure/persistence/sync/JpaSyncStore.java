package br.com.nutrity.vfpsolution.infrastructure.persistence.sync;

import br.com.nutrity.vfpsolution.domain.entity.UserMeal;
import br.com.nutrity.vfpsolution.domain.entity.UserProfile;
import br.com.nutrity.vfpsolution.domain.repository.UserMealRepository;
import br.com.nutrity.vfpsolution.domain.repository.UserProfileRepository;
import br.com.nutrity.vfpsolution.domain.sync.SyncModels;
import br.com.nutrity.vfpsolution.domain.sync.SyncStore;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.nio.charset.StandardCharsets;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaSyncStore implements SyncStore {
    private final SyncChangeJpaRepository changes;
    private final ProcessedSyncOperationJpaRepository processed;
    private final UserProfileRepository users;
    private final UserMealRepository meals;
    private final ObjectMapper mapper;
    public JpaSyncStore(
            SyncChangeJpaRepository changes,
            ProcessedSyncOperationJpaRepository processed,
            UserProfileRepository users,
            UserMealRepository meals,
            ObjectMapper mapper
    ){
        this.changes=changes;
        this.processed=processed;
        this.users=users;
        this.meals=meals;
        this.mapper=mapper;
    }
    @Override
    public void prepareBootstrap(String userId) {
        for (UserMeal meal : meals.findByUserIdOrderByTimestampDesc(userId)) {
            if (findCurrent(userId, SyncModels.EntityType.MEAL, meal.getId()).isPresent()) {
                continue;
            }
            OffsetDateTime modifiedAt = meal.getModifiedAt();
            SyncModels.Operation operation = meal.getDeletedAt() == null
                    ? SyncModels.Operation.UPSERT
                    : SyncModels.Operation.DELETE;
            String seed = "bootstrap|" + userId + "|" + meal.getId() + "|" + modifiedAt.toInstant();
            saveChange(userId, new SyncModels.Mutation(
                    UUID.nameUUIDFromBytes(seed.getBytes(StandardCharsets.UTF_8)),
                    SyncModels.EntityType.MEAL,
                    meal.getId(),
                    operation,
                    modifiedAt,
                    operation == SyncModels.Operation.DELETE ? null : mealPayload(meal)
            ));
        }
    }
    public Optional<ProcessedOperation> findProcessed(String userId, UUID operationId){
        return processed.findByUserIdAndOperationId(userId,operationId.toString()).flatMap(p ->
                changes.findById(p.getChangeSequence()).map(c -> new ProcessedOperation(
                        p.getRequestDigest(),SyncModels.ResultStatus.valueOf(p.getResultStatus()),toDomain(c))));
    }
    public Optional<SyncModels.Change> findCurrent(String userId,SyncModels.EntityType type,String entityId){
        return changes.findTopByUserIdAndEntityTypeAndEntityIdOrderBySequenceDesc(userId,type.name(),entityId).map(this::toDomain);
    }
    public SyncModels.Change saveChange(String userId,SyncModels.Mutation mutation){
        return toDomain(changes.saveAndFlush(new SyncChangeEntity(userId,mutation.entityType().name(),
                mutation.entityId(),mutation.operation().name(),mutation.modifiedAt(),mutation.payloadJson(),
                mutation.operationId().toString())));
    }
    @Override
    public void materialize(String userId, SyncModels.Change change) {
        if (change.entityType() != SyncModels.EntityType.MEAL) {
            return;
        }
        if (change.operation() == SyncModels.Operation.DELETE) {
            meals.findByIdAndUserId(change.entityId(), userId).ifPresent(meal -> {
                meal.applySynchronizedVersion(
                        meal.getDescricao(),
                        meal.getDescricaoOriginal(),
                        meal.getCalorias(),
                        meal.getTimestamp(),
                        meal.getOrigem(),
                        meal.getAiConfidence(),
                        meal.getNota(),
                        meal.getIconKey(),
                        meal.getProteinGrams(),
                        meal.getCarbohydrateGrams(),
                        meal.getFatGrams(),
                        change.modifiedAt(),
                        change.modifiedAt()
                );
                meals.save(meal);
            });
            return;
        }

        JsonNode payload = payload(change.payloadJson());
        JsonNode macros = payload.path("macronutrients");
        UserProfile user = users.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("usuário da sincronização não encontrado"));
        UserMeal meal = meals.findByIdAndUserId(change.entityId(), userId)
                .orElseGet(() -> {
                    if (meals.existsById(change.entityId())) {
                        throw new IllegalStateException("ID de refeição pertence a outra conta");
                    }
                    return new UserMeal(
                            change.entityId(),
                            user,
                            payload.path("description").asText(),
                            optionalText(payload, "originalDescription"),
                            payload.path("calories").asInt(),
                            java.time.OffsetDateTime.parse(payload.path("mealAt").asText()),
                            payload.path("origin").asText(),
                            optionalDouble(payload, "aiConfidence"),
                            optionalText(payload, "note"),
                            payload.path("iconKey").asText(),
                            macros.path("proteinGrams").asInt(),
                            macros.path("carbohydrateGrams").asInt(),
                            macros.path("fatGrams").asInt(),
                            change.modifiedAt(),
                            null
                    );
                });
        meal.applySynchronizedVersion(
                payload.path("description").asText(),
                optionalText(payload, "originalDescription"),
                payload.path("calories").asInt(),
                java.time.OffsetDateTime.parse(payload.path("mealAt").asText()),
                payload.path("origin").asText(),
                optionalDouble(payload, "aiConfidence"),
                optionalText(payload, "note"),
                payload.path("iconKey").asText(),
                macros.path("proteinGrams").asInt(),
                macros.path("carbohydrateGrams").asInt(),
                macros.path("fatGrams").asInt(),
                change.modifiedAt(),
                null
        );
        meals.save(meal);
    }
    public void saveProcessed(String userId,UUID operationId,String digest,SyncModels.ResultStatus status,
                              SyncModels.Change result){
        processed.save(new ProcessedSyncOperationEntity(userId,operationId.toString(),digest,status.name(),
                result.sequence(),OffsetDateTime.now()));
    }
    public List<SyncModels.Change> changesAfter(String userId,long cursor,int limit){
        return changes.findByUserIdAndSequenceGreaterThanOrderBySequenceAsc(userId,cursor,PageRequest.of(0,limit))
                .stream().map(this::toDomain).toList();
    }
    public boolean hasChangesAfter(String userId,long cursor){return changes.existsByUserIdAndSequenceGreaterThan(userId,cursor);}
    private SyncModels.Change toDomain(SyncChangeEntity e){
        return new SyncModels.Change(e.getSequence(),SyncModels.EntityType.valueOf(e.getEntityType()),e.getEntityId(),
                SyncModels.Operation.valueOf(e.getOperation()),e.getModifiedAt(),e.getPayloadJson(),e.getOperationId());
    }

    private JsonNode payload(String payloadJson) {
        try {
            return mapper.readTree(payloadJson);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("payload sincronizado inválido", exception);
        }
    }

    private String mealPayload(UserMeal meal) {
        var payload = mapper.createObjectNode();
        payload.put("description", meal.getDescricao());
        if (meal.getDescricaoOriginal() == null) {
            payload.putNull("originalDescription");
        } else {
            payload.put("originalDescription", meal.getDescricaoOriginal());
        }
        payload.put("calories", meal.getCalorias());
        payload.put("mealAt", meal.getTimestamp().toString());
        payload.put("origin", "audio".equalsIgnoreCase(meal.getOrigem()) ? "audio" : "text");
        if (meal.getAiConfidence() == null) {
            payload.putNull("aiConfidence");
        } else {
            payload.put("aiConfidence", meal.getAiConfidence());
        }
        if (meal.getNota() == null) {
            payload.putNull("note");
        } else {
            payload.put("note", meal.getNota());
        }
        payload.put("iconKey", meal.getIconKey());
        var macros = payload.putObject("macronutrients");
        macros.put("proteinGrams", meal.getProteinGrams());
        macros.put("carbohydrateGrams", meal.getCarbohydrateGrams());
        macros.put("fatGrams", meal.getFatGrams());
        try {
            return mapper.writeValueAsString(payload);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("não foi possível preparar refeição para sincronização", exception);
        }
    }

    private String optionalText(JsonNode payload, String field) {
        JsonNode value = payload.get(field);
        return value == null || value.isNull() ? null : value.asText();
    }

    private Double optionalDouble(JsonNode payload, String field) {
        JsonNode value = payload.get(field);
        return value == null || value.isNull() ? null : value.asDouble();
    }
}
