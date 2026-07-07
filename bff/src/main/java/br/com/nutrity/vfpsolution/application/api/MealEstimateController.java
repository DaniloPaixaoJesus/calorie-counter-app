package br.com.nutrity.vfpsolution.application.api;

import br.com.nutrity.vfpsolution.domain.dto.ai.MealEstimateDto;
import br.com.nutrity.vfpsolution.domain.entityrequest.ai.MealEstimateRequest;
import br.com.nutrity.vfpsolution.domain.service.ai.MealEstimateService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@AllArgsConstructor
@RequestMapping("/ai/meal-estimates")
@Tag(name = "IA de Refeições", description = "Estimativas calóricas e metadados retornados por providers de IA")
public class MealEstimateController {

    private final MealEstimateService service;

    @Operation(summary = "Estima calorias de uma refeição a partir de texto livre")
    @PostMapping
    public ResponseEntity<MealEstimateDto> estimate(
            @Valid @RequestBody MealEstimateRequest request,
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authorizationHeader
    ) {
        return ResponseEntity.ok(service.estimate(request, authorizationHeader));
    }
}
