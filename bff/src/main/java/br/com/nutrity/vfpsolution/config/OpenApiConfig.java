package br.com.nutrity.vfpsolution.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPi() {
        return new OpenAPI()
                .info(getInfo());
    }
    private Info getInfo() {
        return new Info()
                .version("1.0.0")
                .title("Title")
                .description("Description")
                .contact(getContact());
    }

    private Contact getContact() {
        return new Contact()
                .name("Squad Name")
                .email("team@email.com.br");
    }
}
