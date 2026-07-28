package br.com.nutrity.vfpsolution.infrastructure.persistence.sync;

import br.com.nutrity.vfpsolution.domain.sync.SyncModels;
import br.com.nutrity.vfpsolution.domain.sync.SyncStore;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaSyncStore implements SyncStore {
    private final SyncChangeJpaRepository changes;
    private final ProcessedSyncOperationJpaRepository processed;
    public JpaSyncStore(SyncChangeJpaRepository changes,ProcessedSyncOperationJpaRepository processed){
        this.changes=changes;this.processed=processed;
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
}
