package br.com.nutrity.vfpsolution.domain.service.ai;

import br.com.nutrity.vfpsolution.config.ai.AiProviderProperties;
import br.com.nutrity.vfpsolution.domain.ai.*;
import br.com.nutrity.vfpsolution.domain.entityrequest.ai.MealEstimateRequest;
import br.com.nutrity.vfpsolution.domain.service.user.GoogleOAuthValidator;
import br.com.nutrity.vfpsolution.domain.service.user.GoogleTokenInfo;
import br.com.nutrity.vfpsolution.domain.sync.PremiumStatusProvider;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;

import static org.mockito.Mockito.*;

class MealEstimatePremiumPolicyTest {
    @Test void validTokenWithoutActiveSubscriptionUsesFreePolicy(){
        AiProviderProperties props=new AiProviderProperties(); props.setDefaultProvider("fake");
        AiProviderAdapter adapter=mock(AiProviderAdapter.class);
        when(adapter.provider()).thenReturn("fake");
        when(adapter.estimateCalories(anyString(),anyString(),eq(false)))
                .thenReturn(new AiMealEstimate("banana",100,new AiMacronutrients(1,2,3),null,.8,"fruit"));
        GoogleOAuthValidator oauth=mock(GoogleOAuthValidator.class);
        when(oauth.validateOptionalAuthorizationHeader(any())).thenReturn(Optional.of(new GoogleTokenInfo("u@test.dev","aud")));
        PremiumStatusProvider premium=mock(PremiumStatusProvider.class);
        when(premium.isPremiumActiveByEmail("u@test.dev")).thenReturn(false);
        var service=new MealEstimateService(props,List.of(adapter),oauth,premium);
        service.estimate(new MealEstimateRequest("banana",null,null),"Bearer token");
        verify(adapter).estimateCalories(anyString(),anyString(),eq(false));
    }
}
