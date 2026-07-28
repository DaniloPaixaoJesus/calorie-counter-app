package br.com.nutrity.vfpsolution.infrastructure.persistence.sync;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "sync_changes", indexes = @Index(name = "idx_sync_changes_user_sequence", columnList = "user_id,sequence"))
public class SyncChangeEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long sequence;
    @Column(name = "user_id", nullable = false, length = 24)
    private String userId;
    @Column(name = "entity_type", nullable = false, length = 24)
    private String entityType;
    @Column(name = "entity_id", nullable = false, length = 80)
    private String entityId;
    @Column(nullable = false, length = 12)
    private String operation;
    @Column(name = "modified_at", nullable = false)
    private OffsetDateTime modifiedAt;
    @Column(name = "payload_json", columnDefinition = "TEXT")
    private String payloadJson;
    @Column(name = "operation_id", nullable = false, length = 36)
    private String operationId;

    protected SyncChangeEntity() {}
    public SyncChangeEntity(String userId, String entityType, String entityId, String operation,
                            OffsetDateTime modifiedAt, String payloadJson, String operationId) {
        this.userId=userId; this.entityType=entityType; this.entityId=entityId; this.operation=operation;
        this.modifiedAt=modifiedAt; this.payloadJson=payloadJson; this.operationId=operationId;
    }
    public Long getSequence(){return sequence;} public String getUserId(){return userId;}
    public String getEntityType(){return entityType;} public String getEntityId(){return entityId;}
    public String getOperation(){return operation;} public OffsetDateTime getModifiedAt(){return modifiedAt;}
    public String getPayloadJson(){return payloadJson;} public String getOperationId(){return operationId;}
}
