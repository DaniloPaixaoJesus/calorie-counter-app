package br.com.nutrity.vfpsolution.infrastructure.ai;

import br.com.nutrity.vfpsolution.config.ai.AiProviderProperties;
import br.com.nutrity.vfpsolution.domain.ai.AiMealEstimate;
import br.com.nutrity.vfpsolution.domain.ai.AiProviderAdapter;
import br.com.nutrity.vfpsolution.domain.exception.BusinessException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.util.List;
import java.util.Map;

@Component
public class OpenAiGptProviderAdapter implements AiProviderAdapter {

    private static final String SYSTEM_PROMPT = """
            Você estima calorias de refeições em português do Brasil.
            Responda somente JSON válido com os campos:
            descricaoInterpretada, calorias, observacao, confidence, iconKey.
            iconKey deve ser um destes valores: default, protein, grain, legume, vegetable, fruit.
            calorias deve ser inteiro >= 0 e confidence deve estar entre 0.0 e 1.0.
            Quando não houver informação suficiente, use calorias 0, confidence baixo e iconKey default.
            """;

    private final AiProviderProperties.OpenAi properties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;

    public OpenAiGptProviderAdapter(AiProviderProperties properties, ObjectMapper objectMapper) {
        this.properties = properties.getOpenai();
        this.objectMapper = objectMapper;
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(Duration.ofSeconds(this.properties.getTimeoutSeconds()));
        requestFactory.setReadTimeout(Duration.ofSeconds(this.properties.getTimeoutSeconds()));
        this.restClient = RestClient.builder()
                .baseUrl(this.properties.getBaseUrl())
                .requestFactory(requestFactory)
                .build();
    }

    @Override
    public String provider() {
        return "openai-gpt";
    }

    @Override
    public AiMealEstimate estimateCalories(String descricao) {
        if (properties.getApiKey() == null || properties.getApiKey().isBlank()) {
            throw new BusinessException("OPENAI_API_KEY não configurada para o provider openai-gpt");
        }

        try {
            JsonNode response = restClient.post()
                    .uri("/v1/chat/completions")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + properties.getApiKey())
                    .body(requestBody(descricao))
                    .retrieve()
                    .body(JsonNode.class);

            String content = response.path("choices").path(0).path("message").path("content").asText();
            JsonNode estimate = objectMapper.readTree(content);

            return new AiMealEstimate(
                    textValue(estimate, "descricaoInterpretada", descricao),
                    Math.max(estimate.path("calorias").asInt(0), 0),
                    textValue(estimate, "observacao", null),
                    clamp(estimate.path("confidence").asDouble(0.0)),
                    textValue(estimate, "iconKey", "default")
            );
        } catch (BusinessException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new BusinessException("Falha ao estimar calorias com OpenAI GPT", exception);
        }
    }

    private Map<String, Object> requestBody(String descricao) {
        return Map.of(
                "model", properties.getModel(),
                "temperature", 0.2,
                "response_format", Map.of("type", "json_object"),
                "messages", List.of(
                        Map.of("role", "system", "content", SYSTEM_PROMPT),
                        Map.of("role", "user", "content", descricao)
                )
        );
    }

    private String textValue(JsonNode node, String field, String fallback) {
        String value = node.path(field).asText(null);
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private double clamp(double value) {
        return Math.max(0.0, Math.min(1.0, value));
    }
}
