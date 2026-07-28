package br.com.nutrity.vfpsolution.application.sync;

import br.com.nutrity.vfpsolution.domain.entity.UserProfile;
import br.com.nutrity.vfpsolution.domain.repository.UserProfileRepository;
import br.com.nutrity.vfpsolution.domain.sync.PremiumStatusProvider;
import br.com.nutrity.vfpsolution.domain.sync.SyncExceptions;
import org.springframework.stereotype.Service;

@Service
public class SyncAuthorizationService {
    private final UserProfileRepository users;
    private final PremiumStatusProvider premium;
    public SyncAuthorizationService(UserProfileRepository users, PremiumStatusProvider premium) {
        this.users=users; this.premium=premium;
    }
    public void authorize(String userId,String authenticatedEmail) {
        UserProfile user=users.findById(userId)
                .orElseThrow(() -> new SyncExceptions.Unauthorized("Conta autenticada inválida"));
        if(authenticatedEmail==null || !user.getEmail().equalsIgnoreCase(authenticatedEmail.trim()))
            throw new SyncExceptions.Unauthorized("Conta autenticada não corresponde ao recurso");
        if(!premium.isPremiumActive(userId)) throw new SyncExceptions.PremiumRequired();
    }
}
