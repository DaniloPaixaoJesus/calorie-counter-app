package br.com.nutrity.vfpsolution.domain.sync;

public interface PremiumStatusProvider {
    boolean isPremiumActive(String userId);
    boolean isPremiumActiveByEmail(String email);
}
