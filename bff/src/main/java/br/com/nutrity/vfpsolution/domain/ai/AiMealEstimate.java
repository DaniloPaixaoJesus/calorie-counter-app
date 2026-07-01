package br.com.nutrity.vfpsolution.domain.ai;

public record AiMealEstimate(
        String descricaoInterpretada,
        Integer calorias,
        AiMacronutrients macronutrients,
        String observacao,
        Double confidence,
        String iconKey
) {
}
