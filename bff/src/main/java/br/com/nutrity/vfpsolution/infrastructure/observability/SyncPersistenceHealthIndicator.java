package br.com.nutrity.vfpsolution.infrastructure.observability;

import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component("syncPersistence")
public class SyncPersistenceHealthIndicator implements HealthIndicator {
    private final JdbcTemplate jdbc;
    public SyncPersistenceHealthIndicator(JdbcTemplate jdbc){this.jdbc=jdbc;}
    public Health health(){
        try { jdbc.queryForObject("SELECT 1",Integer.class); return Health.up().build(); }
        catch(Exception ex){ return Health.down().withDetail("reason","persistence_unavailable").build(); }
    }
}
