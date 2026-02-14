package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.controller.dto.ConfirmMenuRequest;
import cn.cuckoox.wisediet.controller.dto.MealPlanResponse;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.testcontainers.junit.jupiter.Testcontainers;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.test.StepVerifier;

import java.time.Duration;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
class TodayApiIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtService jwtService;
    @Autowired
    private SessionStore sessionStore;

    @Test
    void shouldReturn401WhenNotAuthenticated() {
        Mono<Boolean> flow = Mono.fromCallable(() -> {
            webTestClient.get()
                    .uri("/api/today/recommendations")
                    .exchange()
                    .expectStatus().isUnauthorized();
            return true;
        }).subscribeOn(Schedulers.boundedElastic());

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldReturn403WhenOnboardingNotComplete() {
        Mono<Boolean> flow = issueAuthenticatedToken(1)
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.get()
                            .uri("/api/today/recommendations")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isForbidden();
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldReturnMockRecommendations() {
        Mono<Boolean> flow = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.get()
                            .uri("/api/today/recommendations")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(MealPlanResponse.class)
                            .value(response -> {
                                assertThat(response.id()).isNotNull();
                                assertThat(response.status()).isEqualTo("pending");
                                assertThat(response.dishes()).hasSize(3);
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldReturnSamePlanOnSecondCall() {
        Mono<Boolean> flow = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    MealPlanResponse first = webTestClient.get()
                            .uri("/api/today/recommendations")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(MealPlanResponse.class)
                            .returnResult()
                            .getResponseBody();

                    MealPlanResponse second = webTestClient.get()
                            .uri("/api/today/recommendations")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(MealPlanResponse.class)
                            .returnResult()
                            .getResponseBody();

                    assertThat(first).isNotNull();
                    assertThat(second).isNotNull();
                    assertThat(first.id()).isEqualTo(second.id());
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldConfirmMenuWithSelectedDishes() {
        Mono<Boolean> flow = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    // First get recommendations
                    MealPlanResponse plan = webTestClient.get()
                            .uri("/api/today/recommendations")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(MealPlanResponse.class)
                            .returnResult()
                            .getResponseBody();

                    assertThat(plan).isNotNull();
                    assertThat(plan.dishes()).hasSizeGreaterThanOrEqualTo(2);

                    // Select first 2 dish IDs
                    List<Long> selectedIds = List.of(
                            plan.dishes().get(0).getId(),
                            plan.dishes().get(1).getId()
                    );

                    // Confirm with selected dishes
                    webTestClient.post()
                            .uri("/api/today/confirm")
                            .header("Authorization", "Bearer " + token)
                            .bodyValue(new ConfirmMenuRequest(selectedIds))
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(MealPlanResponse.class)
                            .value(response -> {
                                assertThat(response.status()).isEqualTo("confirmed");
                                long selectedCount = response.dishes().stream()
                                        .filter(d -> Boolean.TRUE.equals(d.getSelected()))
                                        .count();
                                assertThat(selectedCount).isEqualTo(2);
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    private Mono<String> issueAuthenticatedToken(Integer onboardingStep) {
        String uniqueEmail = "today-api-" + System.nanoTime() + "@test.com";
        return userRepository.save(new User(null, uniqueEmail, "google", "today-api-provider-" + System.nanoTime(), onboardingStep))
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(token -> sessionStore.saveSession(jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }
}
