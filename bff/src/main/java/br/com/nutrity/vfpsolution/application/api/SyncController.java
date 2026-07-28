package br.com.nutrity.vfpsolution.application.api;

import br.com.nutrity.vfpsolution.application.api.sync.SyncRequest;
import br.com.nutrity.vfpsolution.application.api.sync.SyncResponse;
import br.com.nutrity.vfpsolution.application.sync.SyncAuthorizationService;
import br.com.nutrity.vfpsolution.application.sync.SyncService;
import br.com.nutrity.vfpsolution.config.security.GoogleUserTokenFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Validated
@RestController
@RequestMapping("/users/{userId}/sync")
public class SyncController {
    private final SyncAuthorizationService authorization;
    private final SyncService sync;
    public SyncController(SyncAuthorizationService authorization,SyncService sync){
        this.authorization=authorization;this.sync=sync;
    }
    @PostMapping
    public ResponseEntity<SyncResponse> synchronize(
            @PathVariable @Size(max=80) String userId,
            @RequestHeader(value="X-Correlation-Id",required=false) @Size(max=100) String requestedCorrelationId,
            @Valid @RequestBody SyncRequest request,
            HttpServletRequest servletRequest){
        String correlationId=requestedCorrelationId==null||requestedCorrelationId.isBlank()
                ?UUID.randomUUID().toString():requestedCorrelationId;
        Object email=servletRequest.getAttribute(GoogleUserTokenFilter.USER_EMAIL_ATTRIBUTE);
        authorization.authorize(userId,email instanceof String value?value:null);
        return ResponseEntity.ok().header("X-Correlation-Id",correlationId)
                .body(sync.synchronize(userId,request,correlationId));
    }
}
