package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.AdminWhitelist;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.AdminWhitelistRepository;
import cn.cuckoox.wisediet.repository.DishLibraryRepository;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.test.StepVerifier;

import java.time.Duration;
import java.util.Map;

class DishLibraryIntegrationTest extends AbstractIntegrationTest {

    @Autowired private UserRepository userRepository;
    @Autowired private AdminWhitelistRepository adminWhitelistRepository;
    @Autowired private DishLibraryRepository dishLibraryRepository;
    @Autowired private JwtService jwtService;
    @Autowired private SessionStore sessionStore;

    @BeforeEach
    void cleanData() {
        StepVerifier.create(
            dishLibraryRepository.deleteAll()
                .then(adminWhitelistRepository.deleteAll())
                .then(userRepository.deleteAll())
        ).verifyComplete();
    }

    private String createAdminToken() {
        User admin = userRepository.save(new User(null, "admin@test.com", "google", "admin-pid", 0))
                .flatMap(u -> adminWhitelistRepository.save(new AdminWhitelist(null, u.getId())).thenReturn(u))
                .block(Duration.ofSeconds(5));
        String token = jwtService.createAccessToken(admin.getId(), "ADMIN").block(Duration.ofSeconds(5));
        sessionStore.saveSession(jwtService.extractJti(token), admin.getId(), Duration.ofMinutes(15))
                .block(Duration.ofSeconds(5));
        return token;
    }

    private String createUserToken() {
        User user = userRepository.save(new User(null, "plain@test.com", "google", "plain-pid", 0))
                .block(Duration.ofSeconds(5));
        String token = jwtService.createAccessToken(user.getId(), "USER").block(Duration.ofSeconds(5));
        sessionStore.saveSession(jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                .block(Duration.ofSeconds(5));
        return token;
    }

    @Test
    void shouldReturn401_whenNotAuthenticated() {
        webTestClient.get().uri("/api/admin/dishes")
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void shouldReturn403_whenNonAdminAccesses() {
        String token = createUserToken();
        webTestClient.get().uri("/api/admin/dishes")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isForbidden();
    }

    @Test
    void shouldCreateAndListDish_whenAdmin() {
        String token = createAdminToken();

        Map<String, Object> request = Map.of(
                "name", "番茄炒蛋",
                "category", "veggie_mixed",
                "difficulty", 1,
                "prepMin", 5,
                "cookMin", 10,
                "servings", 2,
                "ingredients", "[{\"item\":\"番茄\",\"amount\":200,\"unit\":\"g\"}]",
                "steps", "[\"番茄切块\",\"炒制\"]",
                "nutrientTags", "[\"高蛋白\"]",
                "nutrients", "{\"calories\":150}"
        );

        webTestClient.post().uri("/api/admin/dishes")
                .header("Authorization", "Bearer " + token)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .expectBody()
                .jsonPath("$.id").exists()
                .jsonPath("$.name").isEqualTo("番茄炒蛋")
                .jsonPath("$.isActive").isEqualTo(true);

        webTestClient.get().uri("/api/admin/dishes")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.content[0].name").isEqualTo("番茄炒蛋")
                .jsonPath("$.total").isEqualTo(1);
    }

    @Test
    void shouldToggleDishStatus_whenAdmin() {
        String token = createAdminToken();

        Map<String, Object> request = Map.of(
                "name", "测试菜",
                "category", "meat_red",
                "difficulty", 2,
                "prepMin", 10,
                "cookMin", 20,
                "servings", 2,
                "ingredients", "[]",
                "steps", "[]"
        );

        Long id = webTestClient.post().uri("/api/admin/dishes")
                .header("Authorization", "Bearer " + token)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .returnResult(Map.class)
                .getResponseBody()
                .map(m -> ((Number) m.get("id")).longValue())
                .blockFirst(Duration.ofSeconds(5));

        webTestClient.patch().uri("/api/admin/dishes/" + id + "/status")
                .header("Authorization", "Bearer " + token)
                .bodyValue(Map.of("isActive", false))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.isActive").isEqualTo(false);

        webTestClient.get().uri("/api/admin/dishes?activeOnly=true")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.total").isEqualTo(0);
    }
}
