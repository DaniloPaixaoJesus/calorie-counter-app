package br.com.nutrity.vfpsolution.infrastructure.ai;

import br.com.nutrity.vfpsolution.domain.ai.AiMealEstimate;
import br.com.nutrity.vfpsolution.domain.ai.AiMacronutrients;
import br.com.nutrity.vfpsolution.domain.ai.AiProviderAdapter;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;

@Component
public class MockAiProviderAdapter implements AiProviderAdapter {

    private static final List<FoodRule> FOOD_RULES = List.of(
            new FoodRule("arroz", 170, 4, 38, 1, "grain", "Porção média de arroz cozido."),
            new FoodRule("feijao", 140, 9, 24, 1, "legume", "Porção média de feijão cozido."),
            new FoodRule("feijão", 140, 9, 24, 1, "legume", "Porção média de feijão cozido."),
            new FoodRule("frango", 220, 34, 0, 8, "protein", "Porção média de frango grelhado."),
            new FoodRule("salada", 70, 2, 10, 3, "vegetable", "Porção média de salada simples."),
            new FoodRule("banana", 90, 1, 23, 0, "fruit", "Uma banana média."),
            new FoodRule("ovo", 80, 6, 1, 5, "protein", "Um ovo médio."),
            new FoodRule("pao", 135, 5, 27, 2, "grain", "Um pão francês médio."),
            new FoodRule("pão", 135, 5, 27, 2, "grain", "Um pão francês médio."),
            new FoodRule("pizza", 285, 12, 36, 10, "default", "Uma fatia média de pizza."),
            new FoodRule("hamburguer", 520, 28, 40, 28, "default", "Um hambúrguer médio."),
            new FoodRule("hambúrguer", 520, 28, 40, 28, "default", "Um hambúrguer médio.")
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
                    new AiMacronutrients(0, 0, 0),
                    "Não foi possível reconhecer alimentos suficientes. Revise manualmente.",
                    0.3,
                    "default"
            );
        }

        int calories = matchedRules.stream().mapToInt(FoodRule::calories).sum();
        int proteinGrams = matchedRules.stream().mapToInt(FoodRule::proteinGrams).sum();
        int carbohydrateGrams = matchedRules.stream().mapToInt(FoodRule::carbohydrateGrams).sum();
        int fatGrams = matchedRules.stream().mapToInt(FoodRule::fatGrams).sum();
        String iconKey = matchedRules.getFirst().iconKey();
        double confidence = matchedRules.size() > 1 ? 0.92 : 0.82;
        String note = matchedRules.size() > 1
                ? "Estimativa baseada na soma de porções médias reconhecidas."
                : matchedRules.getFirst().note();

        return new AiMealEstimate(
                normalizedDescription,
                calories,
                new AiMacronutrients(proteinGrams, carbohydrateGrams, fatGrams),
                note,
                confidence,
                iconKey
        );
    }

    private record FoodRule(
            String keyword,
            int calories,
            int proteinGrams,
            int carbohydrateGrams,
            int fatGrams,
            String iconKey,
            String note
    ) {
    }
}
