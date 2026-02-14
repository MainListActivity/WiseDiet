package cn.cuckoox.wisediet.security;

import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import cn.cuckoox.wisediet.repository.UserRepository;
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
    private final UserRepository userRepository;

    public JwtAuthenticationFilter(JwtService jwtService, SessionStore sessionStore, UserRepository userRepository) {
        this.jwtService = jwtService;
        this.sessionStore = sessionStore;
        this.userRepository = userRepository;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        String path = exchange.getRequest().getPath().value();
        if (!requiresAuthentication(path)) {
            return chain.filter(exchange);
        }

        String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return chain.filter(exchange);
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

        return Mono.zip(
                        jwtService.parseUserId(token),
                        sessionStore.userIdBySession(jti)
                                .switchIfEmpty(Mono.error(new IllegalStateException("SESSION_NOT_FOUND")))
                )
                .flatMap(tuple -> {
                    Long tokenUserId = tuple.getT1();
                    Long sessionUserId = tuple.getT2();
                    if (!tokenUserId.equals(sessionUserId)) {
                        return Mono.error(new IllegalStateException("SESSION_USER_MISMATCH"));
                    }
                    return userRepository.findById(sessionUserId)
                            .switchIfEmpty(Mono.error(new IllegalStateException("USER_NOT_FOUND")));
                })
                .flatMap(user -> {
                    Authentication authentication = new UsernamePasswordAuthenticationToken(
                            new AuthenticatedUser(user.getId(), user.getEmail(), user.getOnboardingStep(), jti),
                            token,
                            Collections.emptyList()
                    );
                    return chain.filter(exchange)
                            .contextWrite(ReactiveSecurityContextHolder.withAuthentication(authentication));
                })
                .onErrorResume(ex -> unauthorized(exchange));
    }

    private boolean requiresAuthentication(String path) {
        if (!path.startsWith("/api/")) {
            return false;
        }
        return !path.startsWith("/api/auth/")
                && !path.startsWith("/api/tags/")
                && !"/api/hello".equals(path);
    }

    private Mono<Void> unauthorized(ServerWebExchange exchange) {
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        return exchange.getResponse().setComplete();
    }
}
