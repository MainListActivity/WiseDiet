package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.service.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class AuthFilterIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private JwtService jwtService;

    @Test
    void shouldRejectMissingRedisSession() {
        Mono<Void> flow = jwtService.createAccessToken(42L)
                .flatMap(token -> Mono.fromRunnable(() ->
                        webTestClient.get().uri("/api/secure/ping")
                                .header("Authorization", "Bearer " + token)
                                .exchange()
                                .expectStatus().isUnauthorized()
                ));

        StepVerifier.create(flow)
                .verifyComplete();
    }
}
