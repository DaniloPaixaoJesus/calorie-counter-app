package br.com.nutrity.vfpsolution.config.security;

import br.com.nutrity.vfpsolution.domain.exception.BusinessException;
import br.com.nutrity.vfpsolution.domain.service.user.GoogleOAuthValidator;
import br.com.nutrity.vfpsolution.domain.service.user.GoogleTokenInfo;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

public class GoogleUserTokenFilter extends OncePerRequestFilter {

    public static final String USER_EMAIL_ATTRIBUTE = "nutrity.google.email";

    private final GoogleOAuthValidator googleOAuthValidator;

    public GoogleUserTokenFilter(GoogleOAuthValidator googleOAuthValidator) {
        this.googleOAuthValidator = googleOAuthValidator;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        if (!requiresUserToken(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            GoogleTokenInfo tokenInfo = googleOAuthValidator.validateAuthorizationHeader(
                    request.getHeader("Authorization")
            );
            request.setAttribute(USER_EMAIL_ATTRIBUTE, tokenInfo.email());
            filterChain.doFilter(request, response);
        } catch (BusinessException exception) {
            writeError(response, HttpServletResponse.SC_UNAUTHORIZED, exception.getMessage());
        }
    }

    private boolean requiresUserToken(HttpServletRequest request) {
        String path = request.getRequestURI();
        String contextPath = request.getContextPath();
        if (contextPath != null && !contextPath.isBlank() && path.startsWith(contextPath)) {
            path = path.substring(contextPath.length());
        }
        return path.equals("/users") || path.startsWith("/users/");
    }

    private void writeError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.getWriter().write("{\"mensagem\":\"" + message + "\"}");
    }
}
