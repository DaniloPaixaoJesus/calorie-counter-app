package br.com.nutrity.vfpsolution.domain.entityrequest.user;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record UpdateUserProfileRequest(
        @Size(max = 160)
        String name,

        @Past
        LocalDate birthDate,

        @Size(max = 32)
        String gender,

        @Min(800)
        @Max(6000)
        Integer dailyCalorieGoal,

        @Size(max = 12)
        String locale
) {
}
