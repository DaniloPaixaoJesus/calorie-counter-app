package br.com.nutrity.vfpsolution.application.api;

import org.junit.jupiter.api.Test;
import java.nio.file.Files;
import java.nio.file.Path;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SyncOpenApiComplianceTest {
    @Test void publishedContractContainsEndpointLimitsTimeoutAndErrors() throws Exception {
        Path contract=Path.of("..","specs","004-sincronizar-dados-offline","contracts","openapi.yaml");
        String yaml=Files.readString(contract);
        assertTrue(yaml.contains("/users/{userId}/sync:"));
        assertTrue(yaml.contains("x-timeout-seconds: 30"));
        assertTrue(yaml.contains("maxItems: 100"));
        assertTrue(yaml.contains("\"403\":"));
        assertTrue(yaml.contains("\"409\":"));
        assertTrue(yaml.contains("\"429\":"));
    }
}
