package br.com.nutrity.vfpsolution.config.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

public class AppApiKeyFilter extends OncePerRequestFilter {

    private final AppApiSecurityProperties properties;
    private final Clock clock;
    private final Map<String, WindowCounter> counters = new ConcurrentHashMap<>();

    public AppApiKeyFilter(AppApiSecurityProperties properties) {
        this(properties, Clock.systemUTC());
    }

    AppApiKeyFilter(AppApiSecurityProperties properties, Clock clock) {
        this.properties = properties;
        this.clock = clock;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        if (!requiresProtection(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        if (!properties.isEnabled()) {
            filterChain.doFilter(request, response);
            return;
        }

        String expectedApiKey = properties.getKey();
        if (expectedApiKey == null || expectedApiKey.isBlank()) {
            writeError(response, HttpServletResponse.SC_SERVICE_UNAVAILABLE, "APP_API_KEY não configurada");
            return;
        }

        String providedApiKey = request.getHeader(properties.getHeaderName());
        if (!expectedApiKey.equals(providedApiKey)) {
            writeError(response, HttpServletResponse.SC_UNAUTHORIZED, "API key inválida ou ausente");
            return;
        }

        if (!allowRequest(providedApiKey, clientIp(request))) {
            writeError(response, HttpStatus.TOO_MANY_REQUESTS.value(), "Limite de requisições excedido");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private boolean requiresProtection(HttpServletRequest request) {
        String path = request.getRequestURI();
        String contextPath = request.getContextPath();
        if (contextPath != null && !contextPath.isBlank() && path.startsWith(contextPath)) {
            path = path.substring(contextPath.length());
        }

        return path.equals("/auth") || path.startsWith("/auth/")
                || path.equals("/users") || path.startsWith("/users/");
    }

    private boolean allowRequest(String apiKey, String clientIp) {
        int limit = Math.max(1, properties.getRequestsPerMinute());
        long windowStartEpochSecond = Instant.now(clock).getEpochSecond() / 60;
        String counterKey = apiKey + ":" + clientIp;

        WindowCounter counter = counters.compute(counterKey, (key, current) -> {
            if (current == null || current.windowStartEpochSecond != windowStartEpochSecond) {
                return new WindowCounter(windowStartEpochSecond);
            }
            return current;
        });

        return counter.requests.incrementAndGet() <= limit;
    }

    private String clientIp(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private void writeError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.getWriter().write("{\"mensagem\":\"" + message + "\"}");
    }

    private static class WindowCounter {
        private final long windowStartEpochSecond;
        private final AtomicInteger requests = new AtomicInteger();

        private WindowCounter(long windowStartEpochSecond) {
            this.windowStartEpochSecond = windowStartEpochSecond;
        }
    }
}
