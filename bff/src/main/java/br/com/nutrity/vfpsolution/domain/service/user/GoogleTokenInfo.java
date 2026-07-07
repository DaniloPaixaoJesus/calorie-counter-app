package br.com.nutrity.vfpsolution.domain.service.user;

public record GoogleTokenInfo(
        String email,
        String audience
) {
}
