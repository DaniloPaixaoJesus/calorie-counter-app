package br.com.nutrity.vfpsolution.config;

import br.com.nutrity.vfpsolution.config.security.AppApiKeyFilter;
import br.com.nutrity.vfpsolution.config.security.AppApiSecurityProperties;
import br.com.nutrity.vfpsolution.config.security.GoogleUserTokenFilter;
import br.com.nutrity.vfpsolution.domain.service.user.GoogleOAuthValidator;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableConfigurationProperties(AppApiSecurityProperties.class)
public class SecurityConfig {

    @Bean
    public AppApiKeyFilter appApiKeyFilter(AppApiSecurityProperties properties) {
        return new AppApiKeyFilter(properties);
    }

    @Bean
    public GoogleUserTokenFilter googleUserTokenFilter(GoogleOAuthValidator googleOAuthValidator) {
        return new GoogleUserTokenFilter(googleOAuthValidator);
    }

    @Bean
    public FilterRegistrationBean<AppApiKeyFilter> appApiKeyFilterRegistration(AppApiKeyFilter appApiKeyFilter) {
        FilterRegistrationBean<AppApiKeyFilter> registration = new FilterRegistrationBean<>(appApiKeyFilter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean
    public FilterRegistrationBean<GoogleUserTokenFilter> googleUserTokenFilterRegistration(
            GoogleUserTokenFilter googleUserTokenFilter
    ) {
        FilterRegistrationBean<GoogleUserTokenFilter> registration = new FilterRegistrationBean<>(googleUserTokenFilter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            AppApiKeyFilter appApiKeyFilter,
            GoogleUserTokenFilter googleUserTokenFilter
    ) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(
                        auth -> auth
                                .anyRequest()
                                .permitAll())
                .headers(headers -> headers.frameOptions(HeadersConfigurer.FrameOptionsConfig::sameOrigin))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )
                .addFilterBefore(googleUserTokenFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(appApiKeyFilter, UsernamePasswordAuthenticationFilter.class);
        // .authenticated() // Requer autenticação para qualquer outra rota
        // .httpBasic(); // Usa autenticação HTTP Basic
        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails user = User
                .withUsername("admin")
                .password("{noop}admin123") // {noop} indica que a senha não será criptografada
                .roles("USER")
                .build();

        return new InMemoryUserDetailsManager(user);
    }
}
