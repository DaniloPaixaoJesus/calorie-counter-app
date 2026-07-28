package br.com.nutrity.vfpsolution.infrastructure.persistence;

import br.com.nutrity.vfpsolution.domain.entity.UserProfile;
import br.com.nutrity.vfpsolution.domain.repository.UserProfileRepository;
import br.com.nutrity.vfpsolution.domain.sync.SyncModels;
import br.com.nutrity.vfpsolution.domain.sync.SyncStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class SyncPersistenceTest {
    @Autowired SyncStore store;
    @Autowired UserProfileRepository users;

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
    private UserProfile user(String id,String email){
        var now=OffsetDateTime.now();
        return new UserProfile(id,email,"User",null,null,null,2000,"pt_BR",true,now,now);
    }
}
