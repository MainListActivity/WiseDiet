package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.controller.dto.OAuthLoginRequest;
import cn.cuckoox.wisediet.service.SessionStore;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.test.StepVerifier;

class AuthControllerIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private SessionStore sessionStore;

    @Test
    void shouldReturnTokensForGoogleLogin() {
        String state = "state-123";
        StepVerifier.create(sessionStore.saveOAuthState(state))
                .expectNext(true)
                .verifyComplete();

        webTestClient.post().uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("code-123", state))
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

    @Test
    void shouldCompleteFullOAuthFlowWithStateValidation() throws Exception {
        ObjectMapper objectMapper = new ObjectMapper();

        // Step 1: Get auth URI — state gets stored in Redis
        byte[] body = webTestClient.get().uri("/api/auth/google")
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .returnResult()
                .getResponseBody();

        String state = objectMapper.readTree(body).get("state").asText();

        // Step 2: Login using the state from getAuthUri
        webTestClient.post().uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("code-123", state))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.accessToken").exists()
                .jsonPath("$.refreshToken").exists();
    }

}
