package br.com.nutrity.vfpsolution.domain.dto.user;

import java.time.OffsetDateTime;

public record MealDto(
        String id,
        String userId,
        String descricao,
        String descricaoOriginal,
        Integer calorias,
        OffsetDateTime timestamp,
        String origem,
        Double aiConfidence,
        String nota,
        String iconKey,
        MacronutrientsDto macronutrients
) {
    public record MacronutrientsDto(
            Integer proteinGrams,
            Integer carbohydrateGrams,
            Integer fatGrams
    ) {
    }
}
