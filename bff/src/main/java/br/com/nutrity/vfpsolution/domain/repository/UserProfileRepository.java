package br.com.nutrity.vfpsolution.domain.repository;

import br.com.nutrity.vfpsolution.domain.entity.UserProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserProfileRepository extends JpaRepository<UserProfile, String> {

    Optional<UserProfile> findByEmail(String email);
}
