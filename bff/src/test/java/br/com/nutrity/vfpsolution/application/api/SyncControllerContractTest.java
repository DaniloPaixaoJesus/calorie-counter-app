package br.com.nutrity.vfpsolution.application.api;

import br.com.nutrity.vfpsolution.application.api.sync.SyncResponse;
import br.com.nutrity.vfpsolution.application.sync.SyncAuthorizationService;
import br.com.nutrity.vfpsolution.application.sync.SyncService;
import br.com.nutrity.vfpsolution.config.security.GoogleUserTokenFilter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class SyncControllerContractTest {
    SyncAuthorizationService authorization=mock(SyncAuthorizationService.class);
    SyncService service=mock(SyncService.class);
    MockMvc mvc;
    @BeforeEach void setup(){
        mvc=MockMvcBuilders.standaloneSetup(new SyncController(authorization,service)).build();
    }
    @Test void acceptsContractAndDelegatesAuthenticatedOwnership() throws Exception {
        when(service.synchronize(eq("user-1"),any(),eq("corr")))
                .thenReturn(new SyncResponse(List.of(),List.of(),"0",false,true));
        mvc.perform(post("/users/user-1/sync").requestAttr(GoogleUserTokenFilter.USER_EMAIL_ATTRIBUTE,"u@test.dev")
                        .header("X-Correlation-Id","corr").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"deviceId\":\"00000000-0000-0000-0000-000000000001\",\"bootstrap\":true,\"mutations\":[]}"))
                .andExpect(status().isOk()).andExpect(header().string("X-Correlation-Id","corr"))
                .andExpect(jsonPath("$.premiumActive").value(true));
        verify(authorization).authorize("user-1","u@test.dev");
    }
    @Test void rejectsMoreThanOneHundredMutations() throws Exception {
        String mutation="{\"operationId\":\"00000000-0000-0000-0000-000000000001\",\"entityType\":\"meal\","
                +"\"entityId\":\"m\",\"operation\":\"delete\",\"modifiedAt\":\"2026-01-01T00:00:00Z\"}";
        mvc.perform(post("/users/u/sync").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"deviceId\":\"00000000-0000-0000-0000-000000000001\",\"bootstrap\":false,"
                                +"\"mutations\":["+String.join(",",java.util.Collections.nCopies(101,mutation))+"]}"))
                .andExpect(status().isBadRequest());
        verifyNoInteractions(service);
    }
}
