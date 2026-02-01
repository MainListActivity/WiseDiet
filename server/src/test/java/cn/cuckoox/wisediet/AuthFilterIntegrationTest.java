package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.service.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.test.web.reactive.server.WebTestClient;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class AuthFilterIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private JwtService jwtService;

    @Autowired
    private ApplicationContext context;

    private WebTestClient webTestClient;

    @org.junit.jupiter.api.BeforeEach
    void setUp() {
        webTestClient = WebTestClient.bindToApplicationContext(context).configureClient().build();
    }

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
