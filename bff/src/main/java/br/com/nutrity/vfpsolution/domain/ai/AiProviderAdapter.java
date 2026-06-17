package br.com.nutrity.vfpsolution.domain.ai;

public interface AiProviderAdapter {

    String provider();

    AiMealEstimate estimateCalories(String descricao);
}
