package br.com.nutrity.vfpsolution.infrastructure.persistence.sync;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

interface SyncChangeJpaRepository extends JpaRepository<SyncChangeEntity,Long> {
    Optional<SyncChangeEntity> findTopByUserIdAndEntityTypeAndEntityIdOrderBySequenceDesc(
            String userId,String entityType,String entityId);
    List<SyncChangeEntity> findByUserIdAndSequenceGreaterThanOrderBySequenceAsc(
            String userId,long sequence, Pageable pageable);
    boolean existsByUserIdAndSequenceGreaterThan(String userId,long sequence);
}
