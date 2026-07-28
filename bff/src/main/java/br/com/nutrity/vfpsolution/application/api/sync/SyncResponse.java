package br.com.nutrity.vfpsolution.application.api.sync;

import com.fasterxml.jackson.databind.JsonNode;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record SyncResponse(
        List<MutationResult> results,
        List<RemoteChange> changes,
        String nextCursor,
        boolean hasMore,
        boolean premiumActive
) {
    public record MutationResult(UUID operationId, String status, RemoteChange canonicalChange) {}
    public record RemoteChange(long sequence, String entityType, String entityId, String operation,
                               OffsetDateTime modifiedAt, JsonNode payload) {}
}
