package br.com.nutrity.vfpsolution.application.api;

import br.com.nutrity.vfpsolution.domain.dto.user.UserProfileDto;
import br.com.nutrity.vfpsolution.domain.entityrequest.user.GoogleAuthRequest;
import br.com.nutrity.vfpsolution.domain.service.user.UserPersistenceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@AllArgsConstructor
@RequestMapping("/auth")
@Tag(name = "Autenticação", description = "Fluxos de autenticação mobile")
public class AuthController {

    private final UserPersistenceService userPersistenceService;

    @Operation(summary = "Autentica usuário via Google OAuth e grava perfil em memória")
    @PostMapping("/google")
    public ResponseEntity<UserProfileDto> authenticateGoogle(@Valid @RequestBody GoogleAuthRequest request) {
        return ResponseEntity.ok(userPersistenceService.authenticateWithGoogle(request));
    }
}
