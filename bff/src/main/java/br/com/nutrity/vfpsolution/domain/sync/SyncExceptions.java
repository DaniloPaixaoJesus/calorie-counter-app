package br.com.nutrity.vfpsolution.domain.sync;

public final class SyncExceptions {
    private SyncExceptions() {}

    public static class Unauthorized extends RuntimeException {
        public Unauthorized(String message) { super(message); }
    }
    public static class PremiumRequired extends RuntimeException {
        public PremiumRequired() { super("Assinatura premium ativa é necessária para sincronizar"); }
    }
    public static class IdempotencyConflict extends RuntimeException {
        public IdempotencyConflict() { super("operationId reutilizado com conteúdo diferente"); }
    }
}
