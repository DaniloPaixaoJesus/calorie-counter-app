package br.com.nutrity.vfpsolution.domain.repository;

import br.com.nutrity.vfpsolution.domain.entity.UserMeal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserMealRepository extends JpaRepository<UserMeal, String> {

    List<UserMeal> findByUserIdOrderByTimestampDesc(String userId);
}
