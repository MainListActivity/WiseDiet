package cn.cuckoox.wisediet;

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
import java.util.Map;

class OnboardingI18nIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtService jwtService;
    @Autowired
    private SessionStore sessionStore;

    @Test
    void shouldReturnChineseStrategyWhenLocaleIsZhCn() {
        Mono<Boolean> response = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.get()
                            .uri("/api/onboarding/strategy")
                            .header("Authorization", "Bearer " + token)
                            .header("Accept-Language", "zh-CN")
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(Map.class)
                            .value(payload -> {
                                Map<?, ?> keyPoints = (Map<?, ?>) payload.get("key_points");
                                Map<?, ?> projectedImpact = (Map<?, ?>) payload.get("projected_impact");
                                Map<?, ?> preferences = (Map<?, ?>) payload.get("preferences");
                                if (!"个性化健康策略".equals(payload.get("title"))
                                        || keyPoints == null
                                        || !keyPoints.containsKey("能量")
                                        || projectedImpact == null
                                        || !"+15%".equals(projectedImpact.get("focus_boost"))
                                        || !"2050".equals(projectedImpact.get("calorie_target"))
                                        || preferences == null
                                        || !"专注力提升".equals(preferences.get("daily_focus"))
                                        || payload.get("info_hint") == null
                                        || payload.get("cta_text") == null) {
                                    throw new AssertionError("unexpected i18n strategy payload");
                                }
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(response)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldReturnChineseStrategyWhenLocaleIsZh() {
        Mono<Boolean> response = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.get()
                            .uri("/api/onboarding/strategy")
                            .header("Authorization", "Bearer " + token)
                            .header("Accept-Language", "zh")
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(Map.class)
                            .value(payload -> {
                                Map<?, ?> keyPoints = (Map<?, ?>) payload.get("key_points");
                                if (!"个性化健康策略".equals(payload.get("title")) || keyPoints == null || !keyPoints.containsKey("能量")) {
                                    throw new AssertionError("unexpected i18n strategy payload");
                                }
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(response)
                .expectNext(true)
                .verifyComplete();
    }

    private Mono<String> issueAuthenticatedToken(Integer onboardingStep) {
        return userRepository.save(new User(null, "onboarding-i18n@test.com", "google", "onboarding-i18n-provider-" + System.nanoTime(), onboardingStep))
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(token -> sessionStore.saveSession(jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }
}
