package cn.cuckoox.wisediet;

import org.junit.jupiter.api.Test;
import reactor.core.publisher.Flux;
import reactor.test.StepVerifier;

class HelloControllerI18nIntegrationTest extends AbstractIntegrationTest {

    @Test
    void shouldReturnChineseGreetingWhenLocaleIsZhCn() {
        Flux<String> response = webTestClient.get()
                .uri("/api/hello")
                .header("Accept-Language", "zh-CN")
                .exchange()
                .expectStatus().isOk()
                .returnResult(String.class)
                .getResponseBody();

        StepVerifier.create(response)
                .expectNext("你好，世界！")
                .verifyComplete();
    }
}
