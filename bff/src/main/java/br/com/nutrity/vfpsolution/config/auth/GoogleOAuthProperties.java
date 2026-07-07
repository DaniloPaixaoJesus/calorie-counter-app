package br.com.nutrity.vfpsolution.config.auth;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.ArrayList;
import java.util.List;

@ConfigurationProperties(prefix = "nutrity.auth.google")
public class GoogleOAuthProperties {

    private boolean enabled = true;
    private String tokenInfoUrl = "https://oauth2.googleapis.com/tokeninfo";
    private List<String> allowedAudiences = new ArrayList<>();

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getTokenInfoUrl() {
        return tokenInfoUrl;
    }

    public void setTokenInfoUrl(String tokenInfoUrl) {
        this.tokenInfoUrl = tokenInfoUrl;
    }

    public List<String> getAllowedAudiences() {
        return allowedAudiences;
    }

    public void setAllowedAudiences(List<String> allowedAudiences) {
        this.allowedAudiences = allowedAudiences;
    }
}
