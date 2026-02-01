package cn.cuckoox.wisediet;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;
import com.redis.testcontainers.RedisContainer;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.reactive.server.WebTestClient;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;
import reactor.core.publisher.Mono;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@TestPropertySource(properties = "app.jwt.secret=dev-secret-should-change")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
public abstract class AbstractIntegrationTest {

    @Autowired
    protected ApplicationContext context;

    protected WebTestClient webTestClient;

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>(DockerImageName.parse("postgres:16-alpine"));

    @Container
    static RedisContainer redis = new RedisContainer(DockerImageName.parse("redis:7.4-alpine"));

    private static DisposableServer oauthServer;

    @BeforeEach
    void setUpWebTestClient() {
        webTestClient = WebTestClient.bindToApplicationContext(context).configureClient().build();
    }

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        ensureOauthServer();
        String baseUrl = "http://localhost:" + oauthServer.port();
        registry.add("spring.r2dbc.url", () -> String.format("r2dbc:postgresql://%s:%d/%s",
                postgres.getHost(),
                postgres.getFirstMappedPort(),
                postgres.getDatabaseName()));
        registry.add("spring.r2dbc.username", postgres::getUsername);
        registry.add("spring.r2dbc.password", postgres::getPassword);
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", redis::getFirstMappedPort);

        // Google
        registry.add("spring.security.oauth2.client.registration.google.client-id", () -> "google-client");
        registry.add("spring.security.oauth2.client.registration.google.client-secret", () -> "google-secret");
        registry.add("spring.security.oauth2.client.registration.google.redirect-uri", () -> "http://localhost/redirect");
        registry.add("spring.security.oauth2.client.registration.google.authorization-grant-type", () -> "authorization_code");
        registry.add("spring.security.oauth2.client.registration.google.client-authentication-method", () -> "client_secret_post");
        registry.add("spring.security.oauth2.client.registration.google.scope", () -> "email");
        registry.add("spring.security.oauth2.client.provider.google.token-uri", () -> baseUrl + "/oauth/token/google");
        registry.add("spring.security.oauth2.client.provider.google.user-info-uri", () -> baseUrl + "/oauth/userinfo/google");
        registry.add("spring.security.oauth2.client.provider.google.user-name-attribute", () -> "id");

        // Github
        registry.add("spring.security.oauth2.client.registration.github.client-id", () -> "github-client");
        registry.add("spring.security.oauth2.client.registration.github.client-secret", () -> "github-secret");
        registry.add("spring.security.oauth2.client.registration.github.redirect-uri", () -> "http://localhost/redirect");
        registry.add("spring.security.oauth2.client.registration.github.authorization-grant-type", () -> "authorization_code");
        registry.add("spring.security.oauth2.client.registration.github.client-authentication-method", () -> "client_secret_post");
        registry.add("spring.security.oauth2.client.registration.github.scope", () -> "email");
        registry.add("spring.security.oauth2.client.provider.github.token-uri", () -> baseUrl + "/oauth/token/github");
        registry.add("spring.security.oauth2.client.provider.github.user-info-uri", () -> baseUrl + "/oauth/userinfo/github");
        registry.add("spring.security.oauth2.client.provider.github.user-name-attribute", () -> "id");
    }

    @AfterAll
    static void shutdownOauthServer() {
        if (oauthServer != null) {
            oauthServer.disposeNow();
            oauthServer = null;
        }
    }

    private static void ensureOauthServer() {
        if (oauthServer != null) {
            return;
        }
        oauthServer = HttpServer.create()
                .port(0)
                .route(routes -> routes
                        .post("/oauth/token/google", (request, response) ->
                                response.header("Content-Type", "application/json")
                                        .sendString(Mono.just("{\"access_token\":\"token-google\",\"token_type\":\"Bearer\"}")))
                        .post("/oauth/token/github", (request, response) ->
                                response.header("Content-Type", "application/json")
                                        .sendString(Mono.just("{\"access_token\":\"token-github\",\"token_type\":\"Bearer\"}")))
                        .get("/oauth/userinfo/google", (request, response) ->
                                response.header("Content-Type", "application/json")
                                        .sendString(Mono.just("{\"id\":\"provider-id-1\",\"email\":\"u@test.com\"}")))
                        .get("/oauth/userinfo/github", (request, response) ->
                                response.header("Content-Type", "application/json")
                                        .sendString(Mono.just("{\"id\":\"provider-id-2\",\"email\":\"gh@test.com\"}"))))
                .bindNow();
    }
}
