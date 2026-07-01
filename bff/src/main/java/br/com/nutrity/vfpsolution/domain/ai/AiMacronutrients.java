package br.com.nutrity.vfpsolution.domain.ai;

public record AiMacronutrients(
        Integer proteinGrams,
        Integer carbohydrateGrams,
        Integer fatGrams
) {
    public AiMacronutrients {
        proteinGrams = Math.max(proteinGrams == null ? 0 : proteinGrams, 0);
        carbohydrateGrams = Math.max(carbohydrateGrams == null ? 0 : carbohydrateGrams, 0);
        fatGrams = Math.max(fatGrams == null ? 0 : fatGrams, 0);
    }
}
