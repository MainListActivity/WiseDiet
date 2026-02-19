package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.controller.dto.OAuthLoginRequest;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.SessionStore;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.test.StepVerifier;

class AuthControllerIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private SessionStore sessionStore;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void cleanUsers() {
        StepVerifier.create(userRepository.deleteAll())
                .verifyComplete();
    }

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
                .jsonPath("$.refreshToken").exists()
                .jsonPath("$.onboardingStep").isEqualTo(1);
    }

    @Test
    void shouldReturnOnboardingStepZeroForExistingCompletedUser() {
        // Given: pre-insert a user with onboardingStep=0 who has provider-id-1 (what mock oauth server returns)
        StepVerifier.create(
            userRepository.save(new cn.cuckoox.wisediet.model.User(null, "completed@test.com", "google", "provider-id-1", 0))
        ).expectNextCount(1).verifyComplete();

        String state = "completed-state-1";
        StepVerifier.create(sessionStore.saveOAuthState(state))
                .expectNext(true)
                .verifyComplete();

        webTestClient.post().uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("code-123", state))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.onboardingStep").isEqualTo(0);
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
    void shouldNotCreateDuplicateUserOnRepeatedLogin() {
        // First login
        String state1 = "dup-state-1";
        StepVerifier.create(sessionStore.saveOAuthState(state1))
                .expectNext(true)
                .verifyComplete();

        webTestClient.post().uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("code-123", state1))
                .exchange()
                .expectStatus().isOk();

        Long countAfterFirst = userRepository.findAll()
                .filter(u -> "google".equals(u.getProvider()) && "provider-id-1".equals(u.getProviderUserId()))
                .count().block();

        // Second login with same OAuth provider user
        String state2 = "dup-state-2";
        StepVerifier.create(sessionStore.saveOAuthState(state2))
                .expectNext(true)
                .verifyComplete();

        webTestClient.post().uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("code-123", state2))
                .exchange()
                .expectStatus().isOk();

        Long countAfterSecond = userRepository.findAll()
                .filter(u -> "google".equals(u.getProvider()) && "provider-id-1".equals(u.getProviderUserId()))
                .count().block();

        // Should still be exactly 1 user, not 2
        org.assertj.core.api.Assertions.assertThat(countAfterFirst).isEqualTo(1L);
        org.assertj.core.api.Assertions.assertThat(countAfterSecond).isEqualTo(1L);
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
