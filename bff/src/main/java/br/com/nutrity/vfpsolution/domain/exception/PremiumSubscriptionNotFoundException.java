package br.com.nutrity.vfpsolution.domain.exception;

public class PremiumSubscriptionNotFoundException extends RuntimeException {
    public PremiumSubscriptionNotFoundException() {
        super("Nenhum plano Premium ativo foi encontrado para esta conta");
    }
}
