package br.com.nutrity.vfpsolution.domain.repository;

import br.com.nutrity.vfpsolution.domain.entity.UserMeal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserMealRepository extends JpaRepository<UserMeal, String> {

    List<UserMeal> findByUserIdAndDeletedAtIsNullOrderByTimestampDesc(String userId);

    List<UserMeal> findByUserIdOrderByTimestampDesc(String userId);

    Optional<UserMeal> findByIdAndUserId(String id, String userId);
}
