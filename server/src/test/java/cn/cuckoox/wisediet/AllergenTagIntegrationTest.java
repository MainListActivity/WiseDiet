package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.AllergenTag;
import cn.cuckoox.wisediet.model.DietaryPreferenceTag;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.repository.UserProfileRepository;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.test.StepVerifier;

import java.time.Duration;

class AllergenTagIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserProfileRepository userProfileRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtService jwtService;
    @Autowired
    private SessionStore sessionStore;

    @Test
    void shouldReturnSeededAllergenTags() {
        Flux<AllergenTag> response = webTestClient.get()
                .uri("/api/tags/allergens")
                .exchange()
                .expectStatus().isOk()
                .returnResult(AllergenTag.class)
                .getResponseBody();

        StepVerifier.create(response.filter(tag -> "Peanuts".equals(tag.getLabel())).take(1))
                .expectNextMatches(tag -> "nuts".equals(tag.getCategory()) && "🥜".equals(tag.getEmoji()))
                .verifyComplete();
    }

    @Test
    void shouldReturnSeededDietaryPreferenceTags() {
        Flux<DietaryPreferenceTag> response = webTestClient.get()
                .uri("/api/tags/dietary-preferences")
                .exchange()
                .expectStatus().isOk()
                .returnResult(DietaryPreferenceTag.class)
                .getResponseBody();

        StepVerifier.create(response.filter(tag -> "Vegetarian".equals(tag.getLabel())).take(1))
                .expectNextMatches(tag -> "🌿".equals(tag.getEmoji()))
                .verifyComplete();
    }

    @Test
    void shouldPersistProfileWithAllergenAndDietaryFields() {
        UserProfile request = new UserProfile(
                null, "Female", 25, 165.0, 55.0, "1,2", 2,
                "1,3", "2,4", "Cilantro,Bitter melon"
        );

        Mono<Boolean> requestFlow = issueAuthenticatedToken()
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
                                        || !"1,3".equals(profile.getAllergenTagIds())
                                        || !"2,4".equals(profile.getDietaryPreferenceTagIds())
                                        || !"Cilantro,Bitter melon".equals(profile.getCustomAvoidedIngredients())) {
                                    throw new AssertionError("unexpected saved profile payload");
                                }
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(requestFlow)
                .expectNext(true)
                .verifyComplete();
    }

    private Mono<String> issueAuthenticatedToken() {
        return userRepository.save(new User(null, "allergen-test@test.com", "google", "allergen-test-provider", 0))
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(token -> sessionStore.saveSession(jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }
}
