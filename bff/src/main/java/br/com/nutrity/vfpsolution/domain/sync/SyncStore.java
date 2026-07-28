package br.com.nutrity.vfpsolution.domain.sync;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SyncStore {
    default void prepareBootstrap(String userId) {
    }
    Optional<ProcessedOperation> findProcessed(String userId, UUID operationId);
    Optional<SyncModels.Change> findCurrent(String userId, SyncModels.EntityType type, String entityId);
    SyncModels.Change saveChange(String userId, SyncModels.Mutation mutation);
    default void materialize(String userId, SyncModels.Change change) {
    }
    void saveProcessed(String userId, UUID operationId, String digest,
                       SyncModels.ResultStatus status, SyncModels.Change result);
    List<SyncModels.Change> changesAfter(String userId, long cursor, int limit);
    boolean hasChangesAfter(String userId, long cursor);

    record ProcessedOperation(String digest, SyncModels.ResultStatus status, SyncModels.Change result) {}
}
