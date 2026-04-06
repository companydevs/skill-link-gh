package com.skilllinkgh.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public FirebaseTokenFilter firebaseTokenFilter() {
        return new FirebaseTokenFilter();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                // Analytics open for admin panel (no Firebase token from React)
                .requestMatchers("/api/admin/**").permitAll()
                // Sync endpoint restricted to admin/service accounts
                .requestMatchers("/api/sync/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .addFilterBefore(firebaseTokenFilter(), UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
