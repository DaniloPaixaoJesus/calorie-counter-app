package br.com.nutrity.vfpsolution.application.api.sync;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record SyncRequest(
        @NotNull UUID deviceId,
        boolean bootstrap,
        @Size(max = 500) String cursor,
        @NotNull @Size(max = 100) List<@Valid Mutation> mutations
) {
    public record Mutation(
            @NotNull UUID operationId,
            @NotNull EntityType entityType,
            @NotBlank @Size(max = 80) String entityId,
            @NotNull Operation operation,
            @NotNull OffsetDateTime modifiedAt,
            JsonNode payload
    ) {}

    public enum EntityType { meal, nutritionGoal }
    public enum Operation { upsert, delete }
}
