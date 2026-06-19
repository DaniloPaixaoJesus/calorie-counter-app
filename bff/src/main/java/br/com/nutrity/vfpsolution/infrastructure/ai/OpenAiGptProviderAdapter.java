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
import java.util.Map;

@Component
public class OpenAiGptProviderAdapter implements AiProviderAdapter {

    private static final String SYSTEM_PROMPT = """
            Você estima calorias de refeições em português do Brasil.
            Responda somente JSON válido com os campos:
            descricaoInterpretada, calorias, observacao, confidence, iconKey.
            iconKey deve ser um destes valores: default, protein, grain, legume, vegetable, fruit.
            calorias deve ser inteiro >= 0 e confidence deve estar entre 0.0 e 1.0.
            Use a descrição do usuário como base, mas torne explícitas as premissas de porção.
            Quando a quantidade não for informada, estime usando porções médias brasileiras e explique isso em observacao.
            A observacao deve sempre citar as quantidades/tamanhos assumidos para cada item relevante.
            Para medidas caseiras, especifique o tipo e tamanho da medida assumida, por exemplo:
            colher de sopa cheia ou rasa, colher de chá, concha média, xícara de chá de 200 ml,
            copo americano de 190 ml, unidade média, fatia média, prato raso ou porção em gramas.
            Se o usuário informar "colher" sem tipo/tamanho, assuma colher de sopa rasa e mencione essa premissa.
            Se o usuário informar "xícara" sem tipo/tamanho, assuma xícara de chá de 200 ml e mencione essa premissa.
            Se houver termos vagos como "um pouco", "porção", "prato" ou alimento sem quantidade,
            descreva a porção média assumida e reduza a confidence.
            A descricaoInterpretada deve incluir os alimentos identificados e, quando útil, a porção interpretada.
            Quando não houver alimento reconhecível ou informação mínima suficiente para uma estimativa útil,
            use calorias 0, confidence baixo, iconKey default e explique em observacao quais quantidades faltaram.
            Não use Markdown, não use bloco de código e não inclua texto antes ou depois do JSON.
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
                    .uri("/v1/responses")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + properties.getApiKey())
                    .body(requestBody(descricao))
                    .retrieve()
                    .body(JsonNode.class);

            String content = sanitizeJsonContent(extractOutputText(response));
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
                "input", SYSTEM_PROMPT + "\nDescrição da refeição: " + descricao
        );
    }

    private String extractOutputText(JsonNode response) {
        String outputText = response.path("output_text").asText(null);
        if (outputText != null && !outputText.isBlank()) {
            return outputText;
        }

        for (JsonNode outputItem : response.path("output")) {
            for (JsonNode contentItem : outputItem.path("content")) {
                if ("output_text".equals(contentItem.path("type").asText())) {
                    String text = contentItem.path("text").asText(null);
                    if (text != null && !text.isBlank()) {
                        return text;
                    }
                }
            }
        }

        throw new BusinessException("Resposta inválida da OpenAI: output_text ausente");
    }

    private String sanitizeJsonContent(String content) {
        String sanitized = content.trim();

        if (sanitized.startsWith("```")) {
            sanitized = sanitized
                    .replaceFirst("^```(?:json)?\\s*", "")
                    .replaceFirst("\\s*```$", "")
                    .trim();
        }

        int objectStart = sanitized.indexOf('{');
        int objectEnd = sanitized.lastIndexOf('}');
        if (objectStart >= 0 && objectEnd > objectStart) {
            sanitized = sanitized.substring(objectStart, objectEnd + 1);
        }

        return sanitized;
    }

    private String textValue(JsonNode node, String field, String fallback) {
        String value = node.path(field).asText(null);
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private double clamp(double value) {
        return Math.max(0.0, Math.min(1.0, value));
    }
}
