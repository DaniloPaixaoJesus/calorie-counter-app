package br.com.nutrity.vfpsolution.domain.entityrequest.user;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record GoogleAuthRequest(
        @NotBlank
        @Email
        String email,

        @Size(max = 160)
        String name,

        @Size(max = 600)
        String photoUrl,

        @Size(max = 4096)
        String idToken,

        @Size(max = 4096)
        String accessToken,

        @Size(max = 12)
        String locale
) {
}
