package br.com.nutrity.vfpsolution.domain.service.sync;

import br.com.nutrity.vfpsolution.application.api.sync.SyncRequest;
import br.com.nutrity.vfpsolution.application.sync.SyncService;
import br.com.nutrity.vfpsolution.domain.sync.SyncExceptions;
import br.com.nutrity.vfpsolution.domain.sync.SyncModels;
import br.com.nutrity.vfpsolution.domain.sync.SyncStore;
import br.com.nutrity.vfpsolution.infrastructure.observability.SyncObservability;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;

import java.time.OffsetDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

class SyncServiceConflictTest {
    private final MemoryStore store=new MemoryStore();
    private final SyncService service=new SyncService(store,new ObjectMapper().findAndRegisterModules(),
            new SyncObservability(new SimpleMeterRegistry()));

    @Test void appliesLwwAndDeterministicOperationIdTieBreak(){
        OffsetDateTime at=OffsetDateTime.parse("2026-01-01T10:00:00Z");
        UUID low=UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID high=UUID.fromString("ffffffff-ffff-ffff-ffff-ffffffffffff");
        assertEquals("applied",sync(mutation(low,at,"upsert","{\"description\":\"a\"}"),false).results().getFirst().status());
        assertEquals("applied",sync(mutation(high,at,"delete",null),false).results().getFirst().status());
        assertEquals("ignored",sync(mutation(UUID.randomUUID(),at.minusSeconds(1),"upsert","{}"),false)
                .results().getFirst().status());
    }

    @Test void bootstrapKeepsExistingRemoteAndReplayIsIdempotent(){
        UUID first=UUID.randomUUID();
        sync(mutation(first,OffsetDateTime.parse("2026-01-01T10:00:00Z"),"upsert","{}"),false);
        UUID bootstrap=UUID.randomUUID();
        var ignored=sync(mutation(bootstrap,OffsetDateTime.parse("2027-01-01T10:00:00Z"),"delete",null),true);
        assertEquals("ignored",ignored.results().getFirst().status());
        assertEquals(ignored.results().getFirst(),sync(mutation(bootstrap,
                OffsetDateTime.parse("2027-01-01T10:00:00Z"),"delete",null),true).results().getFirst());
        assertThrows(SyncExceptions.IdempotencyConflict.class,()->sync(mutation(bootstrap,
                OffsetDateTime.parse("2027-01-01T10:00:01Z"),"delete",null),true));
    }

    private br.com.nutrity.vfpsolution.application.api.sync.SyncResponse sync(SyncRequest.Mutation mutation,boolean bootstrap){
        return service.synchronize("u",new SyncRequest(UUID.randomUUID(),bootstrap,null,List.of(mutation)),"test");
    }
    private SyncRequest.Mutation mutation(UUID id,OffsetDateTime at,String operation,String payload){
        try{
            String validPayload=payload==null?null:"{\"description\":\"meal\",\"calories\":100,"
                    +"\"mealAt\":\"2026-01-01T00:00:00Z\",\"origin\":\"text\",\"iconKey\":\"default\","
                    +"\"macronutrients\":{\"proteinGrams\":1,\"carbohydrateGrams\":2,\"fatGrams\":3},"
                    +"\"note\":"+new ObjectMapper().writeValueAsString(payload)+"}";
            return new SyncRequest.Mutation(id,SyncRequest.EntityType.meal,"meal-1",
                SyncRequest.Operation.valueOf(operation),at,validPayload==null?null:new ObjectMapper().readTree(validPayload));}
        catch(Exception e){throw new RuntimeException(e);}
    }

    static class MemoryStore implements SyncStore {
        long sequence; Map<String,SyncModels.Change> current=new HashMap<>(); Map<UUID,ProcessedOperation> processed=new HashMap<>();
        List<SyncModels.Change> feed=new ArrayList<>();
        public Optional<ProcessedOperation> findProcessed(String u,UUID id){return Optional.ofNullable(processed.get(id));}
        public Optional<SyncModels.Change> findCurrent(String u,SyncModels.EntityType t,String id){return Optional.ofNullable(current.get(t+id));}
        public SyncModels.Change saveChange(String u,SyncModels.Mutation m){var c=new SyncModels.Change(++sequence,m.entityType(),
                m.entityId(),m.operation(),m.modifiedAt(),m.payloadJson(),m.operationId().toString());current.put(m.entityType()+m.entityId(),c);feed.add(c);return c;}
        public void saveProcessed(String u,UUID id,String d,SyncModels.ResultStatus s,SyncModels.Change c){processed.put(id,new ProcessedOperation(d,s,c));}
        public List<SyncModels.Change> changesAfter(String u,long c,int l){return feed.stream().filter(x->x.sequence()>c).limit(l).toList();}
        public boolean hasChangesAfter(String u,long c){return feed.stream().anyMatch(x->x.sequence()>c);}
    }
}
