package br.com.nutrity.vfpsolution.infrastructure.persistence.sync;

import org.springframework.data.jpa.repository.JpaRepository;
interface NutritionGoalJpaRepository extends JpaRepository<NutritionGoalEntity,Long> {}
