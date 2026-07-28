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
import java.util.UUID;

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
        String providedApiKey = request.getHeader(properties.getHeaderName());
        boolean validApiKey = expectedApiKey != null
                && !expectedApiKey.isBlank()
                && expectedApiKey.equals(providedApiKey);
        boolean hasGoogleBearer = hasBearerToken(request);
        if (!validApiKey && !hasGoogleBearer) {
            writeError(request,response, HttpServletResponse.SC_UNAUTHORIZED,
                    "UNAUTHORIZED","Autenticação Google inválida ou ausente");
            return;
        }

        String rateLimitCredential = validApiKey ? providedApiKey : "google-bearer";
        if (!allowRequest(rateLimitCredential, clientIp(request))) {
            response.setHeader("Retry-After","60");
            writeError(request,response, HttpStatus.TOO_MANY_REQUESTS.value(),
                    "RATE_LIMITED","Limite temporário de requisições excedido");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private boolean hasBearerToken(HttpServletRequest request) {
        String authorization = request.getHeader("Authorization");
        return authorization != null
                && authorization.regionMatches(true, 0, "Bearer ", 0, "Bearer ".length())
                && !authorization.substring("Bearer ".length()).isBlank();
    }

    private boolean requiresProtection(HttpServletRequest request) {
        String path = request.getRequestURI();
        String contextPath = request.getContextPath();
        if (contextPath != null && !contextPath.isBlank() && path.startsWith(contextPath)) {
            path = path.substring(contextPath.length());
        }

        // O bootstrap do login não pode depender de um segredo embarcado no
        // aplicativo móvel. /auth/google valida o token diretamente no Google;
        // a API key permanece como proteção adicional para dados do usuário.
        return path.equals("/users") || path.startsWith("/users/");
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

    private void writeError(HttpServletRequest request,HttpServletResponse response,int status,String code,String message)
            throws IOException {
        String correlationId=request.getHeader("X-Correlation-Id");
        if(correlationId==null||correlationId.isBlank()||correlationId.length()>100)correlationId=UUID.randomUUID().toString();
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setHeader("X-Correlation-Id",correlationId);
        response.getWriter().write("{\"code\":\""+code+"\",\"message\":\""+message+
                "\",\"correlationId\":\""+correlationId+"\"}");
    }

    private static class WindowCounter {
        private final long windowStartEpochSecond;
        private final AtomicInteger requests = new AtomicInteger();

        private WindowCounter(long windowStartEpochSecond) {
            this.windowStartEpochSecond = windowStartEpochSecond;
        }
    }
}
