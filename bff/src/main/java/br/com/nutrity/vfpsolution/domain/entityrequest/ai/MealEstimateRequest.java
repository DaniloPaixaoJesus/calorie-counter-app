package br.com.nutrity.vfpsolution.domain.entityrequest.ai;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record MealEstimateRequest(
        @NotBlank
        @Size(min = 2, max = 1000)
        String descricao,

        @Size(max = 40)
        String provider
) {
}
