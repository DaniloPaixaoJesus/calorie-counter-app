package br.com.nutrity.vfpsolution.infrastructure.persistence;

import br.com.nutrity.vfpsolution.domain.repository.UserProfileRepository;
import br.com.nutrity.vfpsolution.domain.sync.PremiumStatusProvider;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;

@Component
public class PersistedPremiumStatusProvider implements PremiumStatusProvider {
    private final UserProfileRepository users;
    public PersistedPremiumStatusProvider(UserProfileRepository users) { this.users = users; }
    public boolean isPremiumActive(String userId) {
        return users.findById(userId).map(user -> user.hasActivePremium(OffsetDateTime.now())).orElse(false);
    }
    public boolean isPremiumActiveByEmail(String email) {
        return email != null && users.findByEmail(email.trim().toLowerCase())
                .map(user -> user.hasActivePremium(OffsetDateTime.now())).orElse(false);
    }
}
