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
    public AiMealEstimate estimateCalories(String descricao, String locale) {
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
                    translate(
                            locale,
                            "Not enough foods were recognized. Please review manually.",
                            "Não foi possível reconhecer alimentos suficientes. Revise manualmente.",
                            "No se reconocieron suficientes alimentos. Revisa manualmente."
                    ),
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
                ? translate(
                        locale,
                        "Estimate based on the sum of recognized average portions.",
                        "Estimativa baseada na soma de porções médias reconhecidas.",
                        "Estimación basada en la suma de porciones medias reconocidas."
                )
                : matchedRules.getFirst().note(locale);

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
            String notePt
    ) {
        private String note(String locale) {
            return switch (normalizeLocale(locale)) {
                case "es" -> notePt
                        .replace("Porção média de", "Porción media de")
                        .replace("cozido", "cocido")
                        .replace("grelhado", "a la plancha")
                        .replace("simples", "simple")
                        .replace("Uma banana média.", "Una banana mediana.")
                        .replace("Um ovo médio.", "Un huevo mediano.")
                        .replace("Um pão francês médio.", "Un pan francés mediano.")
                        .replace("Uma fatia média de pizza.", "Una porción mediana de pizza.")
                        .replace("Um hambúrguer médio.", "Una hamburguesa mediana.");
                case "pt_BR" -> notePt;
                default -> notePt
                        .replace("Porção média de", "Average portion of")
                        .replace("arroz cozido.", "cooked rice.")
                        .replace("feijão cozido.", "cooked beans.")
                        .replace("frango grelhado.", "grilled chicken.")
                        .replace("salada simples.", "simple salad.")
                        .replace("Uma banana média.", "One medium banana.")
                        .replace("Um ovo médio.", "One medium egg.")
                        .replace("Um pão francês médio.", "One medium bread roll.")
                        .replace("Uma fatia média de pizza.", "One medium slice of pizza.")
                        .replace("Um hambúrguer médio.", "One medium hamburger.");
            };
        }
    }

    private String translate(String locale, String en, String pt, String es) {
        return switch (normalizeLocale(locale)) {
            case "pt_BR" -> pt;
            case "es" -> es;
            default -> en;
        };
    }

    private static String normalizeLocale(String locale) {
        if (locale == null || locale.isBlank()) {
            return "en_US";
        }
        String normalized = locale.trim().replace('-', '_').toLowerCase(Locale.ROOT);
        if (normalized.equals("pt") || normalized.equals("pt_br")) {
            return "pt_BR";
        }
        if (normalized.equals("es") || normalized.startsWith("es_")) {
            return "es";
        }
        return "en_US";
    }
}
