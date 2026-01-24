package cn.cuckoox.wisediet.api;

import cn.cuckoox.wisediet.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.reactive.server.WebTestClient;

/**
 * Hello World API集成测试
 * 验证WebFlux测试框架配置正确
 */
class HelloControllerIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private WebTestClient webTestClient;

    @Test
    void shouldReturnHelloWorld_whenCallHelloEndpoint() {
        // Given: 准备测试数据（无需准备）
        
        // When: 发送GET请求到 /api/hello
        // Then: 验证响应状态码为200，响应体为"Hello, World!"
        webTestClient.get()
                .uri("/api/hello")
                .exchange()
                .expectStatus().isOk()
                .expectBody(String.class)
                .isEqualTo("Hello, World!");
    }
}
