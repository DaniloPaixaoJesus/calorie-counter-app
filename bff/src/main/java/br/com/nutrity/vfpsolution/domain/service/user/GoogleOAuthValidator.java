package br.com.nutrity.vfpsolution.domain.service.user;

import br.com.nutrity.vfpsolution.config.auth.GoogleOAuthProperties;
import br.com.nutrity.vfpsolution.domain.entityrequest.user.GoogleAuthRequest;
import br.com.nutrity.vfpsolution.domain.exception.BusinessException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@Service
public class GoogleOAuthValidator {

    private static final ParameterizedTypeReference<Map<String, Object>> TOKEN_INFO_TYPE =
            new ParameterizedTypeReference<>() {
            };

    private final GoogleOAuthProperties properties;
    private final RestClient restClient;

    @Autowired
    public GoogleOAuthValidator(GoogleOAuthProperties properties) {
        this(properties, RestClient.builder().baseUrl(properties.getTokenInfoUrl()).build());
    }

    GoogleOAuthValidator(GoogleOAuthProperties properties, RestClient restClient) {
        this.properties = properties;
        this.restClient = restClient;
    }

    public void validate(GoogleAuthRequest request) {
        if (!properties.isEnabled()) {
            return;
        }

        String idToken = trimToNull(request.idToken());
        String accessToken = trimToNull(request.accessToken());
        if (idToken == null && accessToken == null) {
            throw new BusinessException("Token Google ausente");
        }

        Map<String, Object> tokenInfo = idToken == null
                ? fetchTokenInfo("access_token", accessToken)
                : fetchTokenInfo("id_token", idToken);

        validateEmail(request.email(), tokenInfo);
        validateEmailVerified(tokenInfo);
        validateAudience(tokenInfo);
    }

    public GoogleTokenInfo validateAuthorizationHeader(String authorizationHeader) {
        String token = bearerToken(authorizationHeader)
                .orElseThrow(() -> new BusinessException("Token Google ausente"));
        Map<String, Object> tokenInfo = fetchBearerTokenInfo(token);
        validateEmailVerified(tokenInfo);
        validateAudience(tokenInfo);

        String email = readString(tokenInfo, "email");
        if (email == null) {
            throw new BusinessException("Token Google sem e-mail");
        }
        return new GoogleTokenInfo(email, readString(tokenInfo, "aud"));
    }

    public Optional<GoogleTokenInfo> validateOptionalAuthorizationHeader(String authorizationHeader) {
        Optional<String> token = bearerToken(authorizationHeader);
        if (token.isEmpty()) {
            return Optional.empty();
        }

        Map<String, Object> tokenInfo = fetchBearerTokenInfo(token.get());
        validateEmailVerified(tokenInfo);
        validateAudience(tokenInfo);

        String email = readString(tokenInfo, "email");
        if (email == null) {
            throw new BusinessException("Token Google sem e-mail");
        }
        return Optional.of(new GoogleTokenInfo(email, readString(tokenInfo, "aud")));
    }

    private Map<String, Object> fetchTokenInfo(String tokenType, String token) {
        try {
            Map<String, Object> response = restClient.get()
                    .uri(uriBuilder -> uriBuilder.queryParam(tokenType, token).build())
                    .retrieve()
                    .body(TOKEN_INFO_TYPE);
            if (response == null || response.isEmpty()) {
                throw new BusinessException("Token Google inválido");
            }
            return response;
        } catch (RestClientException exception) {
            throw new BusinessException("Token Google inválido");
        }
    }

    private Map<String, Object> fetchBearerTokenInfo(String token) {
        try {
            return fetchTokenInfo("id_token", token);
        } catch (BusinessException ignored) {
            return fetchTokenInfo("access_token", token);
        }
    }

    private void validateEmail(String expectedEmail, Map<String, Object> tokenInfo) {
        String tokenEmail = readString(tokenInfo, "email");
        if (tokenEmail == null) {
            throw new BusinessException("Token Google sem e-mail");
        }
        if (!tokenEmail.equalsIgnoreCase(expectedEmail.trim())) {
            throw new BusinessException("E-mail do token Google não confere");
        }
    }

    private void validateEmailVerified(Map<String, Object> tokenInfo) {
        String emailVerified = readString(tokenInfo, "email_verified");
        if (emailVerified != null && !Boolean.parseBoolean(emailVerified)) {
            throw new BusinessException("E-mail Google não verificado");
        }
    }

    private void validateAudience(Map<String, Object> tokenInfo) {
        if (properties.getAllowedAudiences() == null || properties.getAllowedAudiences().stream()
                .allMatch(value -> value == null || value.isBlank())) {
            return;
        }

        String audience = readString(tokenInfo, "aud");
        if (audience == null) {
            throw new BusinessException("Token Google sem audience");
        }

        boolean allowed = properties.getAllowedAudiences().stream()
                .filter(value -> value != null && !value.isBlank())
                .map(value -> value.trim().toLowerCase(Locale.ROOT))
                .anyMatch(value -> value.equals(audience.trim().toLowerCase(Locale.ROOT)));
        if (!allowed) {
            throw new BusinessException("Audience do token Google não permitida");
        }
    }

    private String readString(Map<String, Object> tokenInfo, String key) {
        Object value = tokenInfo.get(key);
        if (value instanceof String stringValue && !stringValue.isBlank()) {
            return stringValue.trim();
        }
        if (value instanceof Boolean booleanValue) {
            return Boolean.toString(booleanValue);
        }
        return null;
    }

    private String trimToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private Optional<String> bearerToken(String authorizationHeader) {
        String header = trimToNull(authorizationHeader);
        if (header == null) {
            return Optional.empty();
        }
        if (!header.regionMatches(true, 0, "Bearer ", 0, "Bearer ".length())) {
            throw new BusinessException("Authorization Bearer inválido");
        }
        String token = trimToNull(header.substring("Bearer ".length()));
        return token == null ? Optional.empty() : Optional.of(token);
    }
}
