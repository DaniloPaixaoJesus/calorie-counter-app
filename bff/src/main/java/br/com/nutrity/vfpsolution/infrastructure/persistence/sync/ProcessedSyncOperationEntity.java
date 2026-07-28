package br.com.nutrity.vfpsolution.infrastructure.persistence.sync;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "processed_sync_operations",
        uniqueConstraints = @UniqueConstraint(name="uk_processed_user_operation", columnNames={"user_id","operation_id"}))
public class ProcessedSyncOperationEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(name="user_id", nullable=false, length=24) private String userId;
    @Column(name="operation_id", nullable=false, length=36) private String operationId;
    @Column(name="request_digest", nullable=false, length=64) private String requestDigest;
    @Column(name="result_status", nullable=false, length=16) private String resultStatus;
    @Column(name="change_sequence", nullable=false) private Long changeSequence;
    @Column(name="processed_at", nullable=false) private OffsetDateTime processedAt;
    protected ProcessedSyncOperationEntity(){}
    public ProcessedSyncOperationEntity(String userId,String operationId,String requestDigest,String resultStatus,
                                        Long changeSequence,OffsetDateTime processedAt){
        this.userId=userId;this.operationId=operationId;this.requestDigest=requestDigest;
        this.resultStatus=resultStatus;this.changeSequence=changeSequence;this.processedAt=processedAt;
    }
    public String getRequestDigest(){return requestDigest;} public String getResultStatus(){return resultStatus;}
    public Long getChangeSequence(){return changeSequence;}
}
