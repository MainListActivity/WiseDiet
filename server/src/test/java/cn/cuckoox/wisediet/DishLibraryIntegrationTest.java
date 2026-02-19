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
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
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

    // 返回 Mono<String> 而不是 String，避免 .block()
    private Mono<String> createAdminToken() {
        return userRepository.save(new User(null, "admin@test.com", "google", "admin-pid", 0))
                .flatMap(u -> adminWhitelistRepository.save(new AdminWhitelist(null, u.getId())).thenReturn(u))
                .flatMap(u -> jwtService.createAccessToken(u.getId(), "ADMIN")
                        .flatMap(token -> sessionStore.saveSession(jwtService.extractJti(token),
                                u.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }

    private Mono<String> createUserToken() {
        return userRepository.save(new User(null, "plain@test.com", "google", "plain-pid", 0))
                .flatMap(u -> jwtService.createAccessToken(u.getId(), "USER")
                        .flatMap(token -> sessionStore.saveSession(jwtService.extractJti(token),
                                u.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }

    @Test
    void shouldReturn401_whenNotAuthenticated() {
        webTestClient.get().uri("/api/admin/dishes")
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void shouldReturn403_whenNonAdminAccesses() {
        StepVerifier.create(
            createUserToken().flatMap(token ->
                Mono.fromRunnable(() ->
                    webTestClient.get().uri("/api/admin/dishes")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isForbidden()
                ).subscribeOn(Schedulers.boundedElastic())
            )
        ).verifyComplete();
    }

    @Test
    void shouldCreateAndListDish_whenAdmin() {
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

        StepVerifier.create(
            createAdminToken().flatMap(token ->
                Mono.fromRunnable(() -> {
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
                }).subscribeOn(Schedulers.boundedElastic())
            )
        ).verifyComplete();
    }

    @Test
    void shouldToggleDishStatus_whenAdmin() {
        Map<String, Object> createRequest = Map.of(
                "name", "测试菜",
                "category", "meat_red",
                "difficulty", 2,
                "prepMin", 10,
                "cookMin", 20,
                "servings", 2,
                "ingredients", "[]",
                "steps", "[]"
        );

        StepVerifier.create(
            createAdminToken().flatMap(token ->
                Mono.fromRunnable(() -> {
                    // 创建菜品，提取 id
                    Long id = webTestClient.post().uri("/api/admin/dishes")
                            .header("Authorization", "Bearer " + token)
                            .bodyValue(createRequest)
                            .exchange()
                            .expectStatus().isCreated()
                            .returnResult(Map.class)
                            .getResponseBody()
                            .map(m -> ((Number) m.get("id")).longValue())
                            .blockFirst(Duration.ofSeconds(5));

                    // 禁用菜品
                    webTestClient.patch().uri("/api/admin/dishes/" + id + "/status")
                            .header("Authorization", "Bearer " + token)
                            .bodyValue(Map.of("isActive", false))
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody()
                            .jsonPath("$.isActive").isEqualTo(false);

                    // 验证 activeOnly 列表中不存在
                    webTestClient.get().uri("/api/admin/dishes?activeOnly=true")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody()
                            .jsonPath("$.total").isEqualTo(0);
                }).subscribeOn(Schedulers.boundedElastic())
            )
        ).verifyComplete();
    }
}
