package br.com.nutrity.vfpsolution.infrastructure.observability;

import io.micrometer.core.instrument.MeterRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import java.time.Duration;

@Component
public class SyncObservability {
    private static final Logger log=LoggerFactory.getLogger(SyncObservability.class);
    private final MeterRegistry metrics;
    public SyncObservability(MeterRegistry metrics){this.metrics=metrics;}
    public void completed(String correlationId,String result,Duration duration,int mutationCount){
        metrics.counter("nutrity.sync.requests","result",result).increment();
        metrics.timer("nutrity.sync.duration","result",result).record(duration);
        log.info("sync correlationId={} result={} mutations={} durationMs={}",
                correlationId,result,mutationCount,duration.toMillis());
    }
}
