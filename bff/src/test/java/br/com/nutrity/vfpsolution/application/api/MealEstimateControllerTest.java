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

@SpringBootTest
@AutoConfigureMockMvc
class MealEstimateControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldEstimateMealCaloriesWithMockProviderByDefault() throws Exception {
        mockMvc.perform(post("/ai/meal-estimates")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"descricao\":\"arroz, feijão e frango\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.provider", is("mock")))
                .andExpect(jsonPath("$.descricaoInterpretada", is("arroz, feijão e frango")))
                .andExpect(jsonPath("$.calorias", greaterThan(0)))
                .andExpect(jsonPath("$.confidence", greaterThan(0.7)))
                .andExpect(jsonPath("$.iconKey", is("grain")));
    }

    @Test
    void shouldRejectTooShortDescription() throws Exception {
        mockMvc.perform(post("/ai/meal-estimates")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"descricao\":\"a\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldReturnBusinessErrorWhenOpenAiProviderHasNoApiKey() throws Exception {
        mockMvc.perform(post("/ai/meal-estimates")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"descricao\":\"banana\",\"provider\":\"openai-gpt\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.mensagem", is("OPENAI_API_KEY não configurada para o provider openai-gpt")));
    }
}
