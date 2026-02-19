package cn.cuckoox.wisediet.config;

import cn.cuckoox.wisediet.security.JwtAuthenticationFilter;
import cn.cuckoox.wisediet.security.OnboardingGateFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.SecurityWebFiltersOrder;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http, JwtAuthenticationFilter jwtAuthenticationFilter) {
        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .authorizeExchange(exchanges -> exchanges
                        .pathMatchers("/api/auth/**", "/api/tags/**", "/api/hello").permitAll()
                        .pathMatchers("/api/admin/**").authenticated()
                        .pathMatchers("/api/**").authenticated()
                        .pathMatchers("/admin/ui/**").permitAll()
                        .anyExchange().permitAll()
                )
                .addFilterAt(jwtAuthenticationFilter, SecurityWebFiltersOrder.AUTHENTICATION)
                .addFilterAt(new OnboardingGateFilter(), SecurityWebFiltersOrder.AUTHORIZATION)
                .build();
    }
}
