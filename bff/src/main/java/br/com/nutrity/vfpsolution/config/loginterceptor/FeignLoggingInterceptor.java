package br.com.nutrity.vfpsolution.config.loginterceptor;

import feign.RequestInterceptor;
import feign.RequestTemplate;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;

@Component
public class FeignLoggingInterceptor implements RequestInterceptor {

    @Override
    public void apply(RequestTemplate template) {
        String url = template.url();
        MDC.put("integrationEndpoint", url);

        String method = template.method();
        MDC.put("integrationHttpMethod", method);

        String headers = template.headers().toString();
        MDC.put("integrationHeaders", headers);

        String queryParams = template.queries().toString();
        MDC.put("integrationQueryParams", queryParams);

        if (template.body() != null) {
            String body = new String(template.body());
            MDC.put("integrationBody", body);
        }

        String feignAddress = template.request().url();
        MDC.put("integrationAddress", feignAddress);
    }
}
