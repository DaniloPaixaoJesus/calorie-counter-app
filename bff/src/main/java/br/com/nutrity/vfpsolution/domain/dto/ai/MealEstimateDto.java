package br.com.nutrity.vfpsolution.domain.dto.ai;

public record MealEstimateDto(
        String descricaoInterpretada,
        Integer calorias,
        MacronutrientsDto macronutrients,
        String observacao,
        Double confidence,
        String iconKey,
        String provider
) {
    public record MacronutrientsDto(
            Integer proteinGrams,
            Integer carbohydrateGrams,
            Integer fatGrams
    ) {
    }
}
