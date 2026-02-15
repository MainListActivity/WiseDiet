package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.test.StepVerifier;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

public class OnboardingIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtService jwtService;
    @Autowired
    private SessionStore sessionStore;

    @Test
    void shouldReturnSeededOccupationTags() {
        webTestClient.get().uri("/api/tags/occupations")
                .exchange()
                .expectStatus().isOk()
                .expectBodyList(Object.class)
                .hasSize(9)
                .consumeWith(response -> {
                    assertNotNull(response.getResponseBody());
                });
    }

    @Test
    void shouldCreateUserProfile() {
        UserProfile profile = new UserProfile(null, "Male", 30, 175.0, 75.0, "1,2", 1, null, null, null);

        Mono<Boolean> flow = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.post().uri("/api/onboarding/profile")
                            .header("Authorization", "Bearer " + token)
                            .bodyValue(profile)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(UserProfile.class)
                            .consumeWith(response -> {
                                UserProfile saved = response.getResponseBody();
                                assertNotNull(saved);
                                assertNotNull(saved.getId());
                                assertEquals("Male", saved.getGender());
                                assertEquals("1,2", saved.getOccupationTagIds());
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldReturnStrategyReport() {
        Mono<Boolean> flow = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.get().uri("/api/onboarding/strategy")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody()
                            .jsonPath("$.title").exists()
                            .jsonPath("$.key_points").exists();
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    private Mono<String> issueAuthenticatedToken(Integer onboardingStep) {
        return userRepository.save(new User(null, "onboarding-integration@test.com", "google", "onboarding-integration-provider-" + System.nanoTime(), onboardingStep))
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(token -> sessionStore.saveSession(jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }
}
