package br.com.nutrity.vfpsolution.application.api;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "nutrity.security.app-api.key=test-key",
        "nutrity.security.app-api.requests-per-minute=2"
})
@AutoConfigureMockMvc
class MealEstimateControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldEstimateMealCaloriesWithMockProviderByDefault() throws Exception {
        mockMvc.perform(post("/ai/meal-estimates")
                        .header("X-App-Api-Key", "test-key")
                        .header("X-Forwarded-For", "10.0.0.1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"descricao\":\"arroz, feijão e frango\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.provider", is("mock")))
                .andExpect(jsonPath("$.descricaoInterpretada", is("arroz, feijão e frango")))
                .andExpect(jsonPath("$.calorias", greaterThan(0)))
                .andExpect(jsonPath("$.macronutrients.proteinGrams", greaterThan(0)))
                .andExpect(jsonPath("$.macronutrients.carbohydrateGrams", greaterThan(0)))
                .andExpect(jsonPath("$.macronutrients.fatGrams", greaterThan(0)))
                .andExpect(jsonPath("$.confidence", greaterThan(0.7)))
                .andExpect(jsonPath("$.iconKey", is("grain")));
    }

    @Test
    void shouldRejectTooShortDescription() throws Exception {
        mockMvc.perform(post("/ai/meal-estimates")
                        .header("X-App-Api-Key", "test-key")
                        .header("X-Forwarded-For", "10.0.0.2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"descricao\":\"a\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldReturnBusinessErrorWhenOpenAiProviderHasNoApiKey() throws Exception {
        mockMvc.perform(post("/ai/meal-estimates")
                        .header("X-App-Api-Key", "test-key")
                        .header("X-Forwarded-For", "10.0.0.3")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"descricao\":\"banana\",\"provider\":\"openai-gpt\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.mensagem", is("OPENAI_API_KEY não configurada para o provider openai-gpt")));
    }

    @Test
    void shouldRejectAiRequestsWithoutAppApiKey() throws Exception {
        mockMvc.perform(post("/ai/meal-estimates")
                        .header("X-Forwarded-For", "10.0.0.4")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"descricao\":\"banana\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.mensagem", is("API key inválida ou ausente")));
    }

    @Test
    void shouldRateLimitAiRequestsByApiKeyAndClientIp() throws Exception {
        String payload = "{\"descricao\":\"banana\"}";

        mockMvc.perform(post("/ai/meal-estimates")
                        .header("X-App-Api-Key", "test-key")
                        .header("X-Forwarded-For", "10.0.0.5")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk());

        mockMvc.perform(post("/ai/meal-estimates")
                        .header("X-App-Api-Key", "test-key")
                        .header("X-Forwarded-For", "10.0.0.5")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk());

        mockMvc.perform(post("/ai/meal-estimates")
                        .header("X-App-Api-Key", "test-key")
                        .header("X-Forwarded-For", "10.0.0.5")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.mensagem", is("Limite de requisições excedido")));
    }
}
