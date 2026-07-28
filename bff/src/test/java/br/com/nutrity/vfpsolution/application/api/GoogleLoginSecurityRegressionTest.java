package br.com.nutrity.vfpsolution.application.api;

import br.com.nutrity.vfpsolution.domain.repository.UserProfileRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.OffsetDateTime;

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

    @Autowired
    private UserProfileRepository userProfileRepository;

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

    @Test
    void shouldRestoreAnExistingActivePremiumAccount() throws Exception {
        String body = """
                {
                  "email": "restore-active@example.com",
                  "name": "Restore Active",
                  "idToken": "google-id-token",
                  "locale": "pt_BR"
                }
                """;
        mockMvc.perform(post("/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());

        mockMvc.perform(post("/auth/google/restore")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("restore-active@example.com"))
                .andExpect(jsonPath("$.premium").value(true));
    }

    @Test
    void shouldNotCreateAnAccountWhenRestoreHasNoActivePurchase() throws Exception {
        mockMvc.perform(post("/auth/google/restore")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "restore-missing@example.com",
                                  "name": "Restore Missing",
                                  "idToken": "google-id-token",
                                  "locale": "pt_BR"
                                }
                                """))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("PREMIUM_SUBSCRIPTION_NOT_FOUND"));
    }

    @Test
    void shouldRejectRestoreWhenTheExistingPremiumIsInactive() throws Exception {
        String body = """
                {
                  "email": "restore-inactive@example.com",
                  "name": "Restore Inactive",
                  "idToken": "google-id-token",
                  "locale": "pt_BR"
                }
                """;
        mockMvc.perform(post("/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());

        var user = userProfileRepository.findByEmail("restore-inactive@example.com")
                .orElseThrow();
        user.updatePremiumStatus(false, null, OffsetDateTime.now());
        userProfileRepository.saveAndFlush(user);

        mockMvc.perform(post("/auth/google/restore")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("PREMIUM_SUBSCRIPTION_NOT_FOUND"));
    }
}
