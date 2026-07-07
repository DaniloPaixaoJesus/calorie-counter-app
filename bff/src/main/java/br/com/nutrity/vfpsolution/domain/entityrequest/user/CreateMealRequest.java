package br.com.nutrity.vfpsolution.domain.entityrequest.user;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.OffsetDateTime;

public record CreateMealRequest(
        @Size(max = 80)
        String id,

        @NotBlank
        @Size(min = 2, max = 1000)
        String descricao,

        @NotNull
        @Min(0)
        @Max(20000)
        Integer calorias,

        @NotNull
        OffsetDateTime timestamp,

        @NotBlank
        @Size(max = 24)
        String origem,

        @Min(0)
        @Max(1)
        Double aiConfidence,

        @Size(max = 2000)
        String nota,

        @Size(max = 40)
        String iconKey,

        @Valid
        MacronutrientsRequest macronutrients
) {
    public record MacronutrientsRequest(
            @Min(0)
            @Max(5000)
            Integer proteinGrams,

            @Min(0)
            @Max(5000)
            Integer carbohydrateGrams,

            @Min(0)
            @Max(5000)
            Integer fatGrams
    ) {
    }
}
