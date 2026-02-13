package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.controller.dto.OAuthLoginRequest;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.test.StepVerifier;

class AuthControllerIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private SessionStore sessionStore;

    @Test
    void shouldReturnTokensForGoogleLogin() {
        webTestClient.post().uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("code-123", "state-123"))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.accessToken").exists()
                .jsonPath("$.refreshToken").exists();
    }

    @Test
    void shouldRejectLoginWithInvalidState() {
        webTestClient.post().uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("code-123", "invalid-state"))
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void shouldStoreStateInRedisWhenGeneratingAuthUri() {
        webTestClient.get().uri("/api/auth/google")
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.state").value(state -> {
                    StepVerifier.create(sessionStore.validateAndConsumeOAuthState((String) state))
                            .expectNext(true)
                            .verifyComplete();
                });
    }

}
