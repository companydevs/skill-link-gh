package com.skilllinkgh.backend.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.Components;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("SkillLink GH — Recommendation Backend")
                .description("Geo-aware weighted preference ranking engine for posts and reels")
                .version("1.0.0"))
            .addSecurityItem(new SecurityRequirement().addList("Firebase JWT"))
            .components(new Components()
                .addSecuritySchemes("Firebase JWT", new SecurityScheme()
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")
                    .description("Firebase ID token from FirebaseAuth.getInstance().currentUser.getIdToken()")));
    }
}
