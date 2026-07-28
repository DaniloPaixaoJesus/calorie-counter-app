package br.com.nutrity.vfpsolution.config.security;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class AppApiKeyFilterTest {

    @Test
    void allowsGoogleBearerOnUserRoutesWithoutEmbeddedAppApiKey() throws Exception {
        AppApiSecurityProperties properties = new AppApiSecurityProperties();
        properties.setEnabled(true);
        properties.setKey("");
        AppApiKeyFilter filter = new AppApiKeyFilter(properties);
        MockHttpServletRequest request = new MockHttpServletRequest(
                "POST",
                "/users/user-1/sync"
        );
        request.addHeader("Authorization", "Bearer google-token");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertEquals(200, response.getStatus());
        assertEquals(request, chain.getRequest());
    }

    @Test
    void rejectsUserRoutesWithoutGoogleBearerOrValidAppApiKey() throws Exception {
        AppApiSecurityProperties properties = new AppApiSecurityProperties();
        properties.setEnabled(true);
        properties.setKey("");
        AppApiKeyFilter filter = new AppApiKeyFilter(properties);
        MockHttpServletRequest request = new MockHttpServletRequest(
                "POST",
                "/users/user-1/sync"
        );
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertEquals(401, response.getStatus());
        assertNull(chain.getRequest());
    }
}
