package br.com.nutrity.vfpsolution.domain.dto.user;

import java.time.LocalDate;
import java.time.OffsetDateTime;

public record UserProfileDto(
        String id,
        String email,
        String name,
        String photoUrl,
        LocalDate birthDate,
        String gender,
        Integer dailyCalorieGoal,
        String locale,
        Boolean premium,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt
) {
}
