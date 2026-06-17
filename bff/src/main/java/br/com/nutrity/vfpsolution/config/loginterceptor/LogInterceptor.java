package br.com.nutrity.vfpsolution.config.loginterceptor;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class LogInterceptor implements HandlerInterceptor {

    @Autowired
    private Environment environment;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        MDC.put("applicationName", environment.getProperty("spring.application.name", "N/A"));
        MDC.put("applicationVersion", environment.getProperty("spring.application.version", "N/A"));

        String[] activeProfiles = environment.getActiveProfiles();
        MDC.put("profile", String.join(",", activeProfiles));

        MDC.put("endpoint", request.getRequestURI());
        MDC.put("service method", request.getMethod());
        MDC.put("protocol", request.getProtocol());
        MDC.put("port", String.valueOf(request.getServerPort()));

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            MDC.put("loggedUser", authentication.getName());
        } else {
            MDC.put("loggedUser", "Anonymous");
        }

        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        MDC.clear();
    }
}
