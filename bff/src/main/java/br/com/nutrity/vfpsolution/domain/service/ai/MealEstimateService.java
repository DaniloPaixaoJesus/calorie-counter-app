package br.com.nutrity.vfpsolution.domain.service.ai;

import br.com.nutrity.vfpsolution.config.ai.AiProviderProperties;
import br.com.nutrity.vfpsolution.domain.ai.AiMacronutrients;
import br.com.nutrity.vfpsolution.domain.ai.AiProviderAdapter;
import br.com.nutrity.vfpsolution.domain.dto.ai.MealEstimateDto;
import br.com.nutrity.vfpsolution.domain.entityrequest.ai.MealEstimateRequest;
import br.com.nutrity.vfpsolution.domain.exception.BusinessException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class MealEstimateService {

    private final AiProviderProperties properties;
    private final Map<String, AiProviderAdapter> adapters;

    public MealEstimateService(AiProviderProperties properties, List<AiProviderAdapter> adapters) {
        this.properties = properties;
        this.adapters = adapters.stream()
                .collect(Collectors.toMap(adapter -> normalize(adapter.provider()), Function.identity()));
    }

    public MealEstimateDto estimate(MealEstimateRequest request) {
        String provider = normalize(firstNonBlank(request.provider(), properties.getDefaultProvider()));
        AiProviderAdapter adapter = adapters.get(provider);

        if (adapter == null) {
            throw new BusinessException("Provider de IA não suportado: " + provider);
        }

        String locale = normalizeLocale(request.locale());
        var estimate = adapter.estimateCalories(request.descricao().trim(), locale);
        var macronutrients = estimate.macronutrients() == null
                ? new AiMacronutrients(0, 0, 0)
                : estimate.macronutrients();

        return new MealEstimateDto(
                estimate.descricaoInterpretada(),
                estimate.calorias(),
                new MealEstimateDto.MacronutrientsDto(
                        macronutrients.proteinGrams(),
                        macronutrients.carbohydrateGrams(),
                        macronutrients.fatGrams()
                ),
                estimate.observacao(),
                estimate.confidence(),
                estimate.iconKey(),
                adapter.provider()
        );
    }

    private String normalizeLocale(String value) {
        if (value == null || value.isBlank()) {
            return "en_US";
        }
        String normalized = value.trim().replace('-', '_');
        if (normalized.equalsIgnoreCase("pt") || normalized.equalsIgnoreCase("pt_BR")) {
            return "pt_BR";
        }
        if (normalized.equalsIgnoreCase("es") || normalized.toLowerCase(Locale.ROOT).startsWith("es_")) {
            return "es";
        }
        if (normalized.equalsIgnoreCase("en") || normalized.equalsIgnoreCase("en_US")) {
            return "en_US";
        }
        return "en_US";
    }

    private String firstNonBlank(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }
}
