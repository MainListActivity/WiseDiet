package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.controller.dto.OAuthLoginRequest;
import org.junit.jupiter.api.Test;

class AuthControllerIntegrationTest extends AbstractIntegrationTest {

    @Test
    void shouldReturnTokensForGoogleLogin() {
        webTestClient.post().uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("code-123"))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.accessToken").exists()
                .jsonPath("$.refreshToken").exists();
    }

}
