package br.com.nutrity.vfpsolution.domain.ai;

public record AiMealEstimate(
        String descricaoInterpretada,
        Integer calorias,
        String observacao,
        Double confidence,
        String iconKey
) {
}
