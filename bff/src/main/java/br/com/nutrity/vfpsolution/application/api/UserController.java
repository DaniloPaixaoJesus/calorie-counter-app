package br.com.nutrity.vfpsolution.application.api;

import br.com.nutrity.vfpsolution.config.security.GoogleUserTokenFilter;
import br.com.nutrity.vfpsolution.domain.dto.user.MealDto;
import br.com.nutrity.vfpsolution.domain.dto.user.UserProfileDto;
import br.com.nutrity.vfpsolution.domain.entityrequest.user.CreateMealRequest;
import br.com.nutrity.vfpsolution.domain.entityrequest.user.UpdateUserProfileRequest;
import br.com.nutrity.vfpsolution.domain.service.user.UserPersistenceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@AllArgsConstructor
@RequestMapping("/users")
@Tag(name = "Usuários", description = "Perfil, metas e refeições armazenados em memória")
public class UserController {

    private final UserPersistenceService userPersistenceService;

    @Operation(summary = "Busca o perfil do usuário")
    @GetMapping("/{userId}")
    public ResponseEntity<UserProfileDto> getUser(@PathVariable String userId, HttpServletRequest servletRequest) {
        userPersistenceService.assertUserAccess(userId, authenticatedEmail(servletRequest));
        return ResponseEntity.ok(userPersistenceService.findUser(userId));
    }

    @Operation(summary = "Atualiza dados pessoais e meta calórica do usuário")
    @PutMapping("/{userId}")
    public ResponseEntity<UserProfileDto> updateUser(
            @PathVariable String userId,
            @Valid @RequestBody UpdateUserProfileRequest request,
            HttpServletRequest servletRequest
    ) {
        userPersistenceService.assertUserAccess(userId, authenticatedEmail(servletRequest));
        return ResponseEntity.ok(userPersistenceService.updateProfile(userId, request));
    }

    @Operation(summary = "Insere uma refeição para o usuário")
    @PostMapping("/{userId}/meals")
    public ResponseEntity<MealDto> addMeal(
            @PathVariable String userId,
            @Valid @RequestBody CreateMealRequest request,
            HttpServletRequest servletRequest
    ) {
        userPersistenceService.assertUserAccess(userId, authenticatedEmail(servletRequest));
        return ResponseEntity.status(HttpStatus.CREATED).body(userPersistenceService.addMeal(userId, request));
    }

    @Operation(summary = "Lista refeições do usuário")
    @GetMapping("/{userId}/meals")
    public ResponseEntity<List<MealDto>> listMeals(@PathVariable String userId, HttpServletRequest servletRequest) {
        userPersistenceService.assertUserAccess(userId, authenticatedEmail(servletRequest));
        return ResponseEntity.ok(userPersistenceService.listMeals(userId));
    }

    private String authenticatedEmail(HttpServletRequest servletRequest) {
        Object email = servletRequest.getAttribute(GoogleUserTokenFilter.USER_EMAIL_ATTRIBUTE);
        return email instanceof String value ? value : null;
    }
}
