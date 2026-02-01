package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.service.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.TestPropertySource;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

@TestPropertySource(properties = "app.jwt.secret=dev-secret-should-change")
class JwtServiceTest extends AbstractIntegrationTest {

    @Autowired
    private JwtService jwtService;

    @Test
    void shouldCreateAndParseAccessToken() {
        Mono<Long> flow = jwtService.createAccessToken(42L)
                .flatMap(jwtService::parseUserId);

        StepVerifier.create(flow)
                .expectNext(42L)
                .verifyComplete();
    }

    @Test
    void shouldExtractJtiFromToken() {
        Mono<String> flow = jwtService.createAccessToken(7L)
                .map(jwtService::extractJti);

        StepVerifier.create(flow)
                .expectNextMatches(jti -> jti != null && !jti.isBlank())
                .verifyComplete();
    }
}
