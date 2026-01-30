package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.service.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

@SpringBootTest(properties = "app.jwt.secret=dev-secret-should-change")
class JwtServiceTest {

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
}
