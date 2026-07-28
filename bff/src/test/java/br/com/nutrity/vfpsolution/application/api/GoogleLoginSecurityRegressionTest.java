package br.com.nutrity.vfpsolution.application.api;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "nutrity.auth.google.enabled=false",
        "nutrity.security.app-api.enabled=true",
        "nutrity.security.app-api.key="
})
@AutoConfigureMockMvc
class GoogleLoginSecurityRegressionTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldAuthenticateGoogleWithoutRequiringAnEmbeddedAppApiKey() throws Exception {
        mockMvc.perform(post("/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "login-regression@example.com",
                                  "name": "Login Regression",
                                  "idToken": "google-id-token",
                                  "locale": "pt_BR"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("login-regression@example.com"));
    }
}
