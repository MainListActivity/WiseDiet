package cn.cuckoox.wisediet;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
// @Testcontainers // Disabled due to sandbox environment restrictions
public abstract class AbstractIntegrationTest {

    // @Container
    // static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>(DockerImageName.parse("postgres:15"));

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        // Fallback to H2 for CI/Sandbox environment
        registry.add("spring.r2dbc.url", () -> "r2dbc:h2:mem:///wisediet;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE");
        registry.add("spring.r2dbc.username", () -> "sa");
        registry.add("spring.r2dbc.password", () -> "");
    }
}
