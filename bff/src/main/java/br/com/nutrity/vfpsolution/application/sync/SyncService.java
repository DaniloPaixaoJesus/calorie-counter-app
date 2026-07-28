package br.com.nutrity.vfpsolution.application.sync;

import br.com.nutrity.vfpsolution.application.api.sync.SyncRequest;
import br.com.nutrity.vfpsolution.application.api.sync.SyncResponse;
import br.com.nutrity.vfpsolution.domain.sync.SyncExceptions;
import br.com.nutrity.vfpsolution.domain.sync.SyncModels;
import br.com.nutrity.vfpsolution.domain.sync.SyncStore;
import br.com.nutrity.vfpsolution.infrastructure.observability.SyncObservability;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

@Service
public class SyncService {
    private static final int PAGE_SIZE=100;
    private final SyncStore store;
    private final ObjectMapper mapper;
    private final SyncObservability observability;
    public SyncService(SyncStore store,ObjectMapper mapper,SyncObservability observability){
        this.store=store;this.mapper=mapper;this.observability=observability;
    }

    @Transactional
    public SyncResponse synchronize(String userId,SyncRequest request,String correlationId){
        Instant started=Instant.now();
        List<SyncResponse.MutationResult> results=new ArrayList<>();
        for(SyncRequest.Mutation input:request.mutations()) results.add(process(userId,input,request.bootstrap()));
        long cursor=parseCursor(request.cursor());
        List<SyncModels.Change> page=store.changesAfter(userId,cursor,PAGE_SIZE);
        long next=page.isEmpty()?cursor:page.getLast().sequence();
        boolean more=store.hasChangesAfter(userId,next);
        SyncResponse response=new SyncResponse(results,page.stream().map(this::responseChange).toList(),
                Long.toString(next),more,true);
        observability.completed(correlationId,"success",Duration.between(started,Instant.now()),request.mutations().size());
        return response;
    }

    private SyncResponse.MutationResult process(String userId,SyncRequest.Mutation input,boolean bootstrap){
        validate(input);
        String payload=toJson(input.payload());
        SyncModels.Mutation mutation=new SyncModels.Mutation(input.operationId(),toType(input.entityType()),
                input.entityId(),toOperation(input.operation()),input.modifiedAt(),payload);
        String digest=digest(mutation);
        Optional<SyncStore.ProcessedOperation> replay=store.findProcessed(userId,input.operationId());
        if(replay.isPresent()){
            if(!replay.get().digest().equals(digest)) throw new SyncExceptions.IdempotencyConflict();
            return result(input.operationId(),replay.get().status(),replay.get().result());
        }
        Optional<SyncModels.Change> current=store.findCurrent(userId,mutation.entityType(),mutation.entityId());
        boolean wins=current.isEmpty() || (!bootstrap && wins(mutation,current.get()));
        SyncModels.ResultStatus status=wins?SyncModels.ResultStatus.APPLIED:SyncModels.ResultStatus.IGNORED;
        SyncModels.Change canonical=wins?store.saveChange(userId,mutation):current.orElseThrow();
        store.saveProcessed(userId,input.operationId(),digest,status,canonical);
        return result(input.operationId(),status,canonical);
    }
    private boolean wins(SyncModels.Mutation incoming,SyncModels.Change current){
        int time=incoming.modifiedAt().toInstant().compareTo(current.modifiedAt().toInstant());
        return time>0 || (time==0 && incoming.operationId().toString().compareTo(current.winningOperationId())>0);
    }
    private void validate(SyncRequest.Mutation mutation){
        if(mutation.operation()==SyncRequest.Operation.upsert && (mutation.payload()==null||mutation.payload().isNull()))
            throw new IllegalArgumentException("payload é obrigatório para upsert");
        if(mutation.operation()==SyncRequest.Operation.delete && mutation.payload()!=null&&!mutation.payload().isNull())
            throw new IllegalArgumentException("payload deve ser ausente para delete");
        if(mutation.operation()==SyncRequest.Operation.upsert && mutation.entityType()==SyncRequest.EntityType.meal){
            JsonNode p=mutation.payload();
            text(p,"description",2,1000); integer(p,"calories",0,20000); text(p,"mealAt",1,80);
            text(p,"origin",1,24); text(p,"iconKey",1,40);
            JsonNode macros=p.get("macronutrients");
            if(macros==null||!macros.isObject())throw new IllegalArgumentException("macronutrients é obrigatório");
            integer(macros,"proteinGrams",0,5000);integer(macros,"carbohydrateGrams",0,5000);
            integer(macros,"fatGrams",0,5000);
        }
        if(mutation.operation()==SyncRequest.Operation.upsert && mutation.entityType()==SyncRequest.EntityType.nutritionGoal){
            JsonNode p=mutation.payload();
            if(!"dailyCalories".equals(p.path("type").asText()))throw new IllegalArgumentException("type inválido");
            integer(p,"targetValue",800,6000);
            if(!"kcalPerDay".equals(p.path("unit").asText()))throw new IllegalArgumentException("unit inválida");
            text(p,"effectiveFrom",1,20);
        }
    }
    private void text(JsonNode node,String field,int min,int max){
        JsonNode value=node.get(field);
        if(value==null||!value.isTextual()||value.textValue().length()<min||value.textValue().length()>max)
            throw new IllegalArgumentException(field+" inválido");
    }
    private void integer(JsonNode node,String field,int min,int max){
        JsonNode value=node.get(field);
        if(value==null||!value.isIntegralNumber()||value.asInt()<min||value.asInt()>max)
            throw new IllegalArgumentException(field+" inválido");
    }
    private long parseCursor(String cursor){
        if(cursor==null||cursor.isBlank())return 0;
        try{long value=Long.parseLong(cursor);if(value<0)throw new NumberFormatException();return value;}
        catch(NumberFormatException ex){throw new IllegalArgumentException("cursor inválido");}
    }
    private SyncResponse.MutationResult result(UUID id,SyncModels.ResultStatus status,SyncModels.Change change){
        return new SyncResponse.MutationResult(id,status.name().toLowerCase(),responseChange(change));
    }
    private SyncResponse.RemoteChange responseChange(SyncModels.Change c){
        return new SyncResponse.RemoteChange(c.sequence(),c.entityType()==SyncModels.EntityType.MEAL?"meal":"nutritionGoal",
                c.entityId(),c.operation().name().toLowerCase(),c.modifiedAt(),readJson(c.payloadJson()));
    }
    private SyncModels.EntityType toType(SyncRequest.EntityType type){
        return type==SyncRequest.EntityType.meal?SyncModels.EntityType.MEAL:SyncModels.EntityType.NUTRITION_GOAL;
    }
    private SyncModels.Operation toOperation(SyncRequest.Operation op){
        return op==SyncRequest.Operation.upsert?SyncModels.Operation.UPSERT:SyncModels.Operation.DELETE;
    }
    private String toJson(JsonNode node){try{return node==null||node.isNull()?null:mapper.writeValueAsString(node);}
        catch(JsonProcessingException ex){throw new IllegalArgumentException("payload inválido");}}
    private JsonNode readJson(String value){try{return value==null?null:mapper.readTree(value);}
        catch(JsonProcessingException ex){throw new IllegalStateException("payload persistido inválido",ex);}}
    private String digest(SyncModels.Mutation mutation){
        try{
            String value=mutation.operationId()+"|"+mutation.entityType()+"|"+mutation.entityId()+"|"+
                    mutation.operation()+"|"+mutation.modifiedAt().toInstant()+"|"+Objects.toString(mutation.payloadJson(),"");
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        }catch(NoSuchAlgorithmException ex){throw new IllegalStateException(ex);}
    }
}
