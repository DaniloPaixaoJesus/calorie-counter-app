package br.com.nutrity.vfpsolution.infrastructure.persistence.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

interface ProcessedSyncOperationJpaRepository extends JpaRepository<ProcessedSyncOperationEntity,Long> {
    Optional<ProcessedSyncOperationEntity> findByUserIdAndOperationId(String userId,String operationId);
}
