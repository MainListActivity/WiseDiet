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

class AdminUiIntegrationTest extends AbstractIntegrationTest {

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

    private Mono<String> createAdminToken() {
        return userRepository.save(new User(null, "admin@test.com", "google", "admin-ui-pid", 0))
                .flatMap(u -> adminWhitelistRepository.save(new AdminWhitelist(null, u.getId()))
                        .then(jwtService.createAccessToken(u.getId(), "ADMIN"))
                        .flatMap(token -> sessionStore.saveSession(
                                jwtService.extractJti(token), u.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }

    private Mono<String> createUserToken() {
        return userRepository.save(new User(null, "plain@test.com", "google", "plain-ui-pid", 0))
                .flatMap(u -> jwtService.createAccessToken(u.getId(), "USER")
                        .flatMap(token -> sessionStore.saveSession(
                                jwtService.extractJti(token), u.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }

    @Test
    void shouldReturn401_whenNoToken() {
        webTestClient.get().uri("/admin/ui/dishes?token=invalid-token")
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void shouldReturn403_whenNotAdmin() {
        StepVerifier.create(
            createUserToken()
                .flatMap(token -> Mono.fromRunnable(() ->
                    webTestClient.get().uri("/admin/ui/dishes?token=" + token)
                            .exchange()
                            .expectStatus().isForbidden()
                ).subscribeOn(Schedulers.boundedElastic()))
        ).verifyComplete();
    }

    @Test
    void shouldReturn200WithDishList_whenAdmin() {
        StepVerifier.create(
            createAdminToken()
                .flatMap(token -> Mono.fromRunnable(() ->
                    webTestClient.get().uri("/admin/ui/dishes?token=" + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(String.class)
                            .value(body -> org.assertj.core.api.Assertions.assertThat(body)
                                    .contains("菜品库管理"))
                ).subscribeOn(Schedulers.boundedElastic()))
        ).verifyComplete();
    }

    @Test
    void shouldReturn200WithNewForm_whenAdmin() {
        StepVerifier.create(
            createAdminToken()
                .flatMap(token -> Mono.fromRunnable(() ->
                    webTestClient.get().uri("/admin/ui/dishes/new?token=" + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(String.class)
                            .value(body -> org.assertj.core.api.Assertions.assertThat(body)
                                    .contains("新增菜品"))
                ).subscribeOn(Schedulers.boundedElastic()))
        ).verifyComplete();
    }

    @Test
    void shouldCreateDishAndReturnUpdatedList_whenAdmin() {
        StepVerifier.create(
            createAdminToken()
                .flatMap(token -> Mono.fromRunnable(() ->
                    webTestClient.post()
                            .uri("/admin/ui/dishes?token=" + token)
                            .contentType(org.springframework.http.MediaType.APPLICATION_FORM_URLENCODED)
                            .bodyValue("name=测试菜&category=meat_red&difficulty=2&prepMin=10&cookMin=20&servings=2&ingredients=[]&steps=[]")
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(String.class)
                            .value(body -> org.assertj.core.api.Assertions.assertThat(body)
                                    .contains("测试菜"))
                ).subscribeOn(Schedulers.boundedElastic()))
        ).verifyComplete();
    }
}
