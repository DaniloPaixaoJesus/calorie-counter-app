package br.com.nutrity.vfpsolution.infrastructure.persistence;

import br.com.nutrity.vfpsolution.application.api.sync.SyncRequest;
import br.com.nutrity.vfpsolution.application.sync.SyncService;
import br.com.nutrity.vfpsolution.domain.entity.UserProfile;
import br.com.nutrity.vfpsolution.domain.repository.UserMealRepository;
import br.com.nutrity.vfpsolution.domain.repository.UserProfileRepository;
import br.com.nutrity.vfpsolution.domain.sync.SyncModels;
import br.com.nutrity.vfpsolution.domain.sync.SyncStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class SyncPersistenceTest {
    @Autowired SyncStore store;
    @Autowired UserProfileRepository users;
    @Autowired UserMealRepository meals;
    @Autowired SyncService syncService;

    @Test void isolatesFeedByUserAndPersistsTombstoneAndIdempotency(){
        users.save(user("user-a","a@test.dev")); users.save(user("user-b","b@test.dev"));
        UUID operation=UUID.randomUUID();
        var mutation=new SyncModels.Mutation(operation,SyncModels.EntityType.MEAL,"same-id",
                SyncModels.Operation.DELETE,OffsetDateTime.now(),null);
        var change=store.saveChange("user-a",mutation);
        store.saveProcessed("user-a",operation,"digest",SyncModels.ResultStatus.APPLIED,change);
        assertEquals(SyncModels.Operation.DELETE,store.findCurrent("user-a",SyncModels.EntityType.MEAL,"same-id").orElseThrow().operation());
        assertTrue(store.findCurrent("user-b",SyncModels.EntityType.MEAL,"same-id").isEmpty());
        assertEquals("digest",store.findProcessed("user-a",operation).orElseThrow().digest());
    }

    @Test
    void materializesAcceptedMealInUserMealsTable() throws Exception {
        users.save(user("user-meal", "meal@test.dev"));
        UUID operationId = UUID.randomUUID();
        var payload = new com.fasterxml.jackson.databind.ObjectMapper().readTree("""
                {
                  "description": "Arroz e feijão",
                  "originalDescription": "arroz e feijao",
                  "calories": 420,
                  "mealAt": "2026-07-27T12:30:00Z",
                  "origin": "text",
                  "aiConfidence": 0.9,
                  "note": "Almoço",
                  "iconKey": "grain",
                  "macronutrients": {
                    "proteinGrams": 18,
                    "carbohydrateGrams": 62,
                    "fatGrams": 10
                  }
                }
                """);
        var mutation = new SyncRequest.Mutation(
                operationId,
                SyncRequest.EntityType.meal,
                "meal-synced",
                SyncRequest.Operation.upsert,
                OffsetDateTime.parse("2026-07-27T12:31:00Z"),
                payload
        );

        syncService.synchronize(
                "user-meal",
                new SyncRequest(UUID.randomUUID(), false, null, List.of(mutation)),
                "test-correlation"
        );

        var persisted = meals.findById("meal-synced").orElseThrow();
        assertEquals("user-meal", persisted.getUser().getId());
        assertEquals("Arroz e feijão", persisted.getDescricao());
        assertEquals(420, persisted.getCalorias());
        assertEquals(OffsetDateTime.parse("2026-07-27T12:31:00Z"), persisted.getModifiedAt());
    }
    private UserProfile user(String id,String email){
        var now=OffsetDateTime.now();
        return new UserProfile(id,email,"User",null,null,null,2000,"pt_BR",true,now,now);
    }
}
