package br.com.nutrity.vfpsolution.infrastructure.ai;

import br.com.nutrity.vfpsolution.domain.ai.AiMealEstimate;
import br.com.nutrity.vfpsolution.domain.ai.AiProviderAdapter;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;

@Component
public class MockAiProviderAdapter implements AiProviderAdapter {

    private static final List<FoodRule> FOOD_RULES = List.of(
            new FoodRule("arroz", 170, "grain", "Porção média de arroz cozido."),
            new FoodRule("feijao", 140, "legume", "Porção média de feijão cozido."),
            new FoodRule("feijão", 140, "legume", "Porção média de feijão cozido."),
            new FoodRule("frango", 220, "protein", "Porção média de frango grelhado."),
            new FoodRule("salada", 70, "vegetable", "Porção média de salada simples."),
            new FoodRule("banana", 90, "fruit", "Uma banana média."),
            new FoodRule("ovo", 80, "protein", "Um ovo médio."),
            new FoodRule("pao", 135, "grain", "Um pão francês médio."),
            new FoodRule("pão", 135, "grain", "Um pão francês médio."),
            new FoodRule("pizza", 285, "default", "Uma fatia média de pizza."),
            new FoodRule("hamburguer", 520, "default", "Um hambúrguer médio."),
            new FoodRule("hambúrguer", 520, "default", "Um hambúrguer médio.")
    );

    @Override
    public String provider() {
        return "mock";
    }

    @Override
    public AiMealEstimate estimateCalories(String descricao) {
        String normalizedDescription = descricao.trim();
        String comparableDescription = normalizedDescription.toLowerCase(Locale.ROOT);

        List<FoodRule> matchedRules = FOOD_RULES.stream()
                .filter(rule -> comparableDescription.contains(rule.keyword()))
                .toList();

        if (matchedRules.isEmpty()) {
            return new AiMealEstimate(
                    normalizedDescription,
                    0,
                    "Não foi possível reconhecer alimentos suficientes. Revise manualmente.",
                    0.3,
                    "default"
            );
        }

        int calories = matchedRules.stream().mapToInt(FoodRule::calories).sum();
        String iconKey = matchedRules.getFirst().iconKey();
        double confidence = matchedRules.size() > 1 ? 0.92 : 0.82;
        String note = matchedRules.size() > 1
                ? "Estimativa baseada na soma de porções médias reconhecidas."
                : matchedRules.getFirst().note();

        return new AiMealEstimate(normalizedDescription, calories, note, confidence, iconKey);
    }

    private record FoodRule(String keyword, int calories, String iconKey, String note) {
    }
}
