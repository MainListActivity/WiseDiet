package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.UserProfile;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

public class OnboardingIntegrationTest extends AbstractIntegrationTest {

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
        UserProfile profile = new UserProfile(null, "Male", 30, 175.0, 75.0, "1,2", 1);

        webTestClient.post().uri("/api/onboarding/profile")
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
    }

    @Test
    void shouldReturnStrategyReport() {
        webTestClient.get().uri("/api/onboarding/strategy")
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.title").isEqualTo("Personalized Health Strategy")
                .jsonPath("$.key_points.Energy").exists();
    }
}
