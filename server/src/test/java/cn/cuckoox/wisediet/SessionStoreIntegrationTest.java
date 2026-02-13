package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.service.SessionStore;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class SessionStoreIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private SessionStore sessionStore;

    @Test
    void shouldSaveAndFindSession() {
        Mono<Boolean> flow = sessionStore.saveSession("jti-1", 42L, Duration.ofMinutes(15))
                .then(sessionStore.exists("jti-1"));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldSaveAndFindOAuthState() {
        Mono<Boolean> flow = sessionStore.saveOAuthState("test-state-123")
                .then(sessionStore.validateAndConsumeOAuthState("test-state-123"));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldRejectUnknownOAuthState() {
        StepVerifier.create(sessionStore.validateAndConsumeOAuthState("never-stored"))
                .expectNext(false)
                .verifyComplete();
    }

    @Test
    void shouldConsumeOAuthStateOnlyOnce() {
        Mono<Boolean> flow = sessionStore.saveOAuthState("once-state")
                .then(sessionStore.validateAndConsumeOAuthState("once-state"))
                .flatMap(first -> sessionStore.validateAndConsumeOAuthState("once-state"));

        StepVerifier.create(flow)
                .expectNext(false)
                .verifyComplete();
    }
}
