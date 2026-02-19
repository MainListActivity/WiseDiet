package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.controller.dto.AuthTokenResponse;
import cn.cuckoox.wisediet.controller.dto.OAuthLoginRequest;
import cn.cuckoox.wisediet.model.AdminWhitelist;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.AdminWhitelistRepository;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.test.StepVerifier;

class AdminLoginIntegrationTest extends AbstractIntegrationTest {

    @Autowired private UserRepository userRepository;
    @Autowired private AdminWhitelistRepository adminWhitelistRepository;
    @Autowired private SessionStore sessionStore;
    @Autowired private JwtService jwtService;

    @BeforeEach
    void cleanData() {
        StepVerifier.create(
            adminWhitelistRepository.deleteAll()
                .then(userRepository.deleteAll())
        ).verifyComplete();
    }

    @Test
    void shouldReturnAdminRoleInToken_whenUserIsInAdminWhitelist() {
        String state = "test-state-admin";

        StepVerifier.create(
            sessionStore.saveOAuthState(state)
                .then(userRepository.save(new User(null, "u@test.com", "google", "provider-id-1", 0)))
                .flatMap(user -> adminWhitelistRepository.save(new AdminWhitelist(null, user.getId())))
                .then()
        ).verifyComplete();

        StepVerifier.create(
            webTestClient.post()
                .uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("mock-code", state))
                .exchange()
                .expectStatus().isOk()
                .returnResult(AuthTokenResponse.class)
                .getResponseBody()
                .doOnNext(response -> {
                    String role = jwtService.extractRole(response.accessToken());
                    org.junit.jupiter.api.Assertions.assertEquals("ADMIN", role, "Expected ADMIN role but got: " + role);
                })
        ).expectNextCount(1).verifyComplete();
    }

    @Test
    void shouldReturnUserRoleInToken_whenUserIsNotInAdminWhitelist() {
        String state = "test-state-user";

        StepVerifier.create(sessionStore.saveOAuthState(state)).expectNextCount(1).verifyComplete();

        StepVerifier.create(
            webTestClient.post()
                .uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("mock-code", state))
                .exchange()
                .expectStatus().isOk()
                .returnResult(AuthTokenResponse.class)
                .getResponseBody()
                .doOnNext(response -> {
                    String role = jwtService.extractRole(response.accessToken());
                    org.junit.jupiter.api.Assertions.assertEquals("USER", role, "Expected USER role but got: " + role);
                })
        ).expectNextCount(1).verifyComplete();
    }
}
