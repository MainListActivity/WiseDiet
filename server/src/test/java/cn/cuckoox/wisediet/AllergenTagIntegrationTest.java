package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.AllergenTag;
import cn.cuckoox.wisediet.model.DietaryPreferenceTag;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Flux;
import reactor.test.StepVerifier;

class AllergenTagIntegrationTest extends AbstractIntegrationTest {

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
}
