package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.OccupationTag;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.repository.UserProfileRepository;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Testcontainers;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.test.StepVerifier;
import java.time.Duration;
import java.util.Map;

@Testcontainers
class OnboardingApiIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserProfileRepository userProfileRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtService jwtService;
    @Autowired
    private SessionStore sessionStore;

    @Test
    void shouldReturnSeededOccupationTags() {
        // Given: 已加载默认标签数据
        // When: 请求职业标签列表
        Flux<OccupationTag> response = webTestClient.get()
                .uri("/api/tags/occupations")
                .exchange()
                .expectStatus().isOk()
                .returnResult(OccupationTag.class)
                .getResponseBody();

        // Then: 返回职业标签并包含预置数据
        StepVerifier.create(response.filter(tag -> "Programmer (Sedentary)".equals(tag.getLabel())).take(1))
                .expectNextMatches(tag -> "Occupation".equals(tag.getCategory()))
                .verifyComplete();
    }

    @Test
    void shouldPersistProfileFromOnboarding() {
        // Given: 完整的基础信息与职业标签
        UserProfile request = new UserProfile(
                null,
                "Male",
                30,
                180.0,
                70.0,
                "1,2",
                2,
                null,
                null,
                null
        );

        // When: 提交 onboarding 资料
        Mono<Boolean> requestFlow = issueAuthenticatedToken(0)
                .delayElement(Duration.ofMillis(100))
                .flatMap(authToken -> Mono.fromCallable(() -> {
                    webTestClient.post()
                            .uri("/api/onboarding/profile")
                            .header("Authorization", "Bearer " + authToken)
                            .bodyValue(request)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(UserProfile.class)
                            .value(profile -> {
                                if (profile.getId() == null
                                        || !"Male".equals(profile.getGender())
                                        || !Integer.valueOf(2).equals(profile.getFamilyMembers())) {
                                    throw new AssertionError("unexpected saved profile payload");
                                }
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        // Then: 返回持久化数据并写入数据库
        StepVerifier.create(requestFlow)
                .expectNext(true)
                .verifyComplete();

        StepVerifier.create(userProfileRepository.findAll()
                        .filter(profile -> "Male".equals(profile.getGender()))
                        .take(1))
                .expectNextMatches(profile -> "1,2".equals(profile.getOccupationTagIds()))
                .verifyComplete();
    }

    @Test
    void shouldReturnEnhancedStrategyPayload() {
        Mono<Boolean> response = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.get()
                            .uri("/api/onboarding/strategy")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(Map.class)
                            .value(payload -> {
                                Map<?, ?> projectedImpact = (Map<?, ?>) payload.get("projected_impact");
                                Map<?, ?> preferences = (Map<?, ?>) payload.get("preferences");
                                if (projectedImpact == null
                                        || !projectedImpact.containsKey("focus_boost")
                                        || !projectedImpact.containsKey("calorie_target")
                                        || preferences == null
                                        || !preferences.containsKey("daily_focus")
                                        || !preferences.containsKey("meal_frequency")
                                        || !preferences.containsKey("cooking_level")
                                        || !preferences.containsKey("budget")
                                        || payload.get("info_hint") == null
                                        || payload.get("cta_text") == null) {
                                    throw new AssertionError("missing enhanced strategy fields");
                                }
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(response)
                .expectNext(true)
                .verifyComplete();
    }

    private Mono<String> issueAuthenticatedToken(Integer onboardingStep) {
        return userRepository.save(new User(null, "onboarding-api@test.com", "google", "onboarding-api-provider", onboardingStep))
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(token -> sessionStore.saveSession(jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }
}
