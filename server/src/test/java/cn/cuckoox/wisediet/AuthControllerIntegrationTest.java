package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.controller.dto.OAuthLoginRequest;
import cn.cuckoox.wisediet.service.OAuthClient;
import cn.cuckoox.wisediet.service.OAuthProfile;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.ApplicationContext;
import org.springframework.test.web.reactive.server.WebTestClient;

class AuthControllerIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private ApplicationContext context;

    private WebTestClient webTestClient;

    @Test
    void shouldReturnTokensForGoogleLogin() {
        webTestClient = WebTestClient.bindToApplicationContext(context).configureClient().build();
        webTestClient.post().uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("code-123"))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.accessToken").exists()
                .jsonPath("$.refreshToken").exists();
    }

    @TestConfiguration
    static class TestConfig {
        @Bean
        OAuthClient oauthClient() {
            return new OAuthClient() {
                @Override
                public reactor.core.publisher.Mono<OAuthProfile> exchangeAndFetchProfile(String provider, String code) {
                    return reactor.core.publisher.Mono.just(new OAuthProfile("u@test.com", "google", "gid-1"));
                }
            };
        }
    }
}
