package br.com.nutrity.vfpsolution.domain.dto.ai;

public record MealEstimateDto(
        String descricaoInterpretada,
        Integer calorias,
        String observacao,
        Double confidence,
        String iconKey,
        String provider
) {
}
