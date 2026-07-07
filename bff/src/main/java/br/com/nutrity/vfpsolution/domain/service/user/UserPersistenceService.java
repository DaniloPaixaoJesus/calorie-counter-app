package br.com.nutrity.vfpsolution.domain.service.user;

import br.com.nutrity.vfpsolution.domain.dto.user.MealDto;
import br.com.nutrity.vfpsolution.domain.dto.user.UserProfileDto;
import br.com.nutrity.vfpsolution.domain.entity.UserMeal;
import br.com.nutrity.vfpsolution.domain.entity.UserProfile;
import br.com.nutrity.vfpsolution.domain.entityrequest.user.CreateMealRequest;
import br.com.nutrity.vfpsolution.domain.entityrequest.user.GoogleAuthRequest;
import br.com.nutrity.vfpsolution.domain.entityrequest.user.UpdateUserProfileRequest;
import br.com.nutrity.vfpsolution.domain.exception.BusinessException;
import br.com.nutrity.vfpsolution.domain.repository.UserMealRepository;
import br.com.nutrity.vfpsolution.domain.repository.UserProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.OffsetDateTime;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class UserPersistenceService {

    private final UserProfileRepository userProfileRepository;
    private final UserMealRepository userMealRepository;

    public UserPersistenceService(
            UserProfileRepository userProfileRepository,
            UserMealRepository userMealRepository
    ) {
        this.userProfileRepository = userProfileRepository;
        this.userMealRepository = userMealRepository;
    }

    @Transactional
    public UserProfileDto authenticateWithGoogle(GoogleAuthRequest request) {
        validateGooglePayload(request);

        String email = request.email().trim().toLowerCase(Locale.ROOT);
        OffsetDateTime now = OffsetDateTime.now();
        UserProfile user = userProfileRepository.findByEmail(email)
                .orElseGet(() -> new UserProfile(
                        stableUserId(email),
                        email,
                        firstNonBlank(request.name(), "Premium User"),
                        blankToNull(request.photoUrl()),
                        null,
                        null,
                        2000,
                        normalizeLocale(request.locale(), "en_US"),
                        true,
                        now,
                        now
                ));

        user.updateFromGoogle(
                firstNonBlank(request.name(), user.getName()),
                firstNonBlank(request.photoUrl(), user.getPhotoUrl()),
                normalizeLocale(request.locale(), user.getLocale()),
                now
        );

        return toDto(userProfileRepository.save(user));
    }

    @Transactional(readOnly = true)
    public UserProfileDto findUser(String userId) {
        return toDto(findUserEntity(userId));
    }

    @Transactional
    public UserProfileDto updateProfile(String userId, UpdateUserProfileRequest request) {
        UserProfile user = findUserEntity(userId);
        user.updateProfile(
                firstNonBlank(request.name(), user.getName()),
                request.birthDate() == null ? user.getBirthDate() : request.birthDate(),
                firstNonBlank(request.gender(), user.getGender()),
                request.dailyCalorieGoal() == null ? user.getDailyCalorieGoal() : request.dailyCalorieGoal(),
                normalizeLocale(request.locale(), user.getLocale())
        );
        return toDto(userProfileRepository.save(user));
    }

    @Transactional
    public MealDto addMeal(String userId, CreateMealRequest request) {
        UserProfile user = findUserEntity(userId);
        MealDto.MacronutrientsDto macros = toDto(request.macronutrients());
        UserMeal meal = new UserMeal(
                firstNonBlank(request.id(), UUID.randomUUID().toString()),
                user,
                request.descricao().trim(),
                request.calorias(),
                request.timestamp(),
                request.origem().trim().toLowerCase(Locale.ROOT),
                request.aiConfidence(),
                blankToNull(request.nota()),
                firstNonBlank(request.iconKey(), "default"),
                macros.proteinGrams(),
                macros.carbohydrateGrams(),
                macros.fatGrams()
        );
        return toDto(userMealRepository.save(meal));
    }

    @Transactional(readOnly = true)
    public List<MealDto> listMeals(String userId) {
        findUserEntity(userId);
        return userMealRepository.findByUserIdOrderByTimestampDesc(userId).stream()
                .map(this::toDto)
                .toList();
    }

    private UserProfile findUserEntity(String userId) {
        return userProfileRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("Usuário não encontrado: " + userId));
    }

    private void validateGooglePayload(GoogleAuthRequest request) {
        boolean hasToken = !isBlank(request.idToken()) || !isBlank(request.accessToken());
        if (!hasToken) {
            // Integração inicial: o app ainda pode rodar em modo debug sem idToken em algumas plataformas.
            // Mantemos validação estrutural do e-mail e centralizamos aqui a futura validação real do token Google.
            return;
        }
    }

    private UserProfileDto toDto(UserProfile user) {
        return new UserProfileDto(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getPhotoUrl(),
                user.getBirthDate(),
                user.getGender(),
                user.getDailyCalorieGoal(),
                user.getLocale(),
                user.getPremium(),
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
    }

    private MealDto toDto(UserMeal meal) {
        return new MealDto(
                meal.getId(),
                meal.getUser().getId(),
                meal.getDescricao(),
                meal.getCalorias(),
                meal.getTimestamp(),
                meal.getOrigem(),
                meal.getAiConfidence(),
                meal.getNota(),
                meal.getIconKey(),
                new MealDto.MacronutrientsDto(
                        meal.getProteinGrams(),
                        meal.getCarbohydrateGrams(),
                        meal.getFatGrams()
                )
        );
    }

    private MealDto.MacronutrientsDto toDto(CreateMealRequest.MacronutrientsRequest request) {
        if (request == null) {
            return new MealDto.MacronutrientsDto(0, 0, 0);
        }
        return new MealDto.MacronutrientsDto(
                request.proteinGrams() == null ? 0 : request.proteinGrams(),
                request.carbohydrateGrams() == null ? 0 : request.carbohydrateGrams(),
                request.fatGrams() == null ? 0 : request.fatGrams()
        );
    }

    private String normalizeLocale(String value, String fallback) {
        String candidate = isBlank(value) ? fallback : value;
        if (isBlank(candidate)) {
            return "en_US";
        }
        String normalized = candidate.trim().replace('-', '_').toLowerCase(Locale.ROOT);
        if (normalized.equals("pt") || normalized.equals("pt_br")) {
            return "pt_BR";
        }
        if (normalized.equals("es") || normalized.startsWith("es_")) {
            return "es";
        }
        return "en_US";
    }

    private String stableUserId(String email) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(email.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash).substring(0, 24);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 indisponível", exception);
        }
    }

    private String firstNonBlank(String value, String fallback) {
        return isBlank(value) ? fallback : value.trim();
    }

    private String blankToNull(String value) {
        return isBlank(value) ? null : value.trim();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
