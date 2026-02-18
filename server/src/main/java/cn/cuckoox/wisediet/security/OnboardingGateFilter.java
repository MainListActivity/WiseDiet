package cn.cuckoox.wisediet.security;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

public class OnboardingGateFilter implements WebFilter {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        String path = exchange.getRequest().getPath().value();
        if (path.startsWith("/api/auth/") || path.startsWith("/api/onboarding/")) {
            return chain.filter(exchange);
        }

        return ReactiveSecurityContextHolder.getContext()
                .flatMap(ctx -> {
                    Authentication auth = ctx.getAuthentication();
                    if (auth != null && auth.isAuthenticated()
                            && auth.getPrincipal() instanceof AuthenticatedUser user
                            && user.onboardingStep() != null && user.onboardingStep() > 0) {
                        exchange.getResponse().setStatusCode(HttpStatus.FORBIDDEN);
                        exchange.getResponse().getHeaders().add("X-Error-Code", "ONBOARDING_REQUIRED");
                        return exchange.getResponse().setComplete().then(Mono.just(true));
                    }
                    return chain.filter(exchange).then(Mono.just(true));
                })
                .switchIfEmpty(chain.filter(exchange).then(Mono.just(true)))
                .then();
    }
}
