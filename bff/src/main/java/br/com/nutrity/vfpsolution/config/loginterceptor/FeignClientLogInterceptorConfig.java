package br.com.nutrity.vfpsolution.config.loginterceptor;

import org.springframework.context.annotation.Bean;
import feign.Logger;
import feign.RequestInterceptor;

public class FeignClientLogInterceptorConfig {
    @Bean
    public RequestInterceptor feignLoggingInterceptor() {
        return new FeignLoggingInterceptor();
    }

    @Bean
    Logger.Level feignLoggerLevel() {
        return Logger.Level.FULL;
    }
}
