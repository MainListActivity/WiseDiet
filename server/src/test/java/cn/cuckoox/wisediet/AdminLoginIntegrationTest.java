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

import java.time.Duration;

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

        // AbstractIntegrationTest 的 mock OAuth server 固定返回 provider_user_id = "provider-id-1", email = "u@test.com"
        // 先预存 user + 白名单，再走 OAuth 登录
        StepVerifier.create(
            sessionStore.saveOAuthState(state)
                .then(userRepository.save(new User(null, "u@test.com", "google", "provider-id-1", 0)))
                .flatMap(user -> adminWhitelistRepository.save(new AdminWhitelist(null, user.getId())))
                .then()
        ).verifyComplete();

        AuthTokenResponse response = webTestClient.post()
                .uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("mock-code", state))
                .exchange()
                .expectStatus().isOk()
                .returnResult(AuthTokenResponse.class)
                .getResponseBody()
                .blockFirst(Duration.ofSeconds(5));

        assert response != null;
        String role = jwtService.extractRole(response.accessToken());
        assert "ADMIN".equals(role) : "Expected ADMIN role but got: " + role;
    }

    @Test
    void shouldReturnUserRoleInToken_whenUserIsNotInAdminWhitelist() {
        String state = "test-state-user";

        StepVerifier.create(sessionStore.saveOAuthState(state)).expectNext(true).verifyComplete();

        AuthTokenResponse response = webTestClient.post()
                .uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("mock-code", state))
                .exchange()
                .expectStatus().isOk()
                .returnResult(AuthTokenResponse.class)
                .getResponseBody()
                .blockFirst(Duration.ofSeconds(5));

        assert response != null;
        String role = jwtService.extractRole(response.accessToken());
        assert "USER".equals(role) : "Expected USER role but got: " + role;
    }
}
