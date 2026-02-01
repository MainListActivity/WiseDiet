package cn.cuckoox.wisediet.security;

import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import java.util.Collections;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

@Component
public class JwtAuthenticationFilter implements WebFilter {

    private final JwtService jwtService;
    private final SessionStore sessionStore;

    public JwtAuthenticationFilter(JwtService jwtService, SessionStore sessionStore) {
        this.jwtService = jwtService;
        this.sessionStore = sessionStore;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        String path = exchange.getRequest().getPath().value();
        if (!path.startsWith("/api/secure/") && !path.startsWith("/api/admin/")) {
            return chain.filter(exchange);
        }

        String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }

        String token = authHeader.substring("Bearer ".length());
        String jti;
        try {
            jti = jwtService.extractJti(token);
        } catch (Exception ex) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
        if (jti == null || jti.isBlank()) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }

        return sessionStore.exists(jti)
                .flatMap(exists -> {
                    if (!exists) {
                        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
                        return exchange.getResponse().setComplete();
                    }
                    return jwtService.parseUserId(token)
                            .flatMap(userId -> {
                                Authentication authentication = new UsernamePasswordAuthenticationToken(
                                        userId,
                                        token,
                                        Collections.emptyList()
                                );
                                return chain.filter(exchange)
                                        .contextWrite(ReactiveSecurityContextHolder.withAuthentication(authentication));
                            })
                            .onErrorResume(ex -> {
                                exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
                                return exchange.getResponse().setComplete();
                            });
                });
    }
}
