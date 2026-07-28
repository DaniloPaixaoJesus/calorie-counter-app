package br.com.nutrity.vfpsolution.domain.sync;

import java.time.OffsetDateTime;
import java.util.UUID;

public final class SyncModels {
    private SyncModels() {}

    public enum EntityType { MEAL, NUTRITION_GOAL }
    public enum Operation { UPSERT, DELETE }
    public enum ResultStatus { APPLIED, IGNORED }

    public record Mutation(
            UUID operationId,
            EntityType entityType,
            String entityId,
            Operation operation,
            OffsetDateTime modifiedAt,
            String payloadJson
    ) {}

    public record Change(
            long sequence,
            EntityType entityType,
            String entityId,
            Operation operation,
            OffsetDateTime modifiedAt,
            String payloadJson,
            String winningOperationId
    ) {}
}
