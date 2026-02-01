package cn.cuckoox.wisediet.security;

import cn.cuckoox.wisediet.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

@Component
public class OnboardingGateFilter implements WebFilter {

    private final UserRepository userRepository;

    public OnboardingGateFilter(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        String path = exchange.getRequest().getPath().value();
        if (path.startsWith("/auth/") || path.startsWith("/api/onboarding/")) {
            return chain.filter(exchange);
        }

        return ReactiveSecurityContextHolder.getContext()
                .map(context -> context.getAuthentication())
                .filter(Authentication::isAuthenticated)
                .flatMap(auth -> userRepository.findById((Long) auth.getPrincipal())
                        .flatMap(user -> {
                            if (user.getOnboardingStep() != null && user.getOnboardingStep() > 0) {
                                exchange.getResponse().setStatusCode(HttpStatus.FORBIDDEN);
                                exchange.getResponse().getHeaders().add("X-Error-Code", "ONBOARDING_REQUIRED");
                                return exchange.getResponse().setComplete();
                            }
                            return chain.filter(exchange);
                        }))
                .switchIfEmpty(chain.filter(exchange));
    }
}
