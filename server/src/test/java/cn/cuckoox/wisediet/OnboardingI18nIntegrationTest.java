package cn.cuckoox.wisediet;

import org.junit.jupiter.api.Test;
import reactor.core.publisher.Flux;
import reactor.test.StepVerifier;

import java.util.Map;

class OnboardingI18nIntegrationTest extends AbstractIntegrationTest {

    @Test
    void shouldReturnChineseStrategyWhenLocaleIsZhCn() {
        Flux<Map> response = webTestClient.get()
                .uri("/api/onboarding/strategy")
                .header("Accept-Language", "zh-CN")
                .exchange()
                .expectStatus().isOk()
                .returnResult(Map.class)
                .getResponseBody();

        StepVerifier.create(response)
                .expectNextMatches(payload -> "个性化健康策略".equals(payload.get("title"))
                        && ((Map<?, ?>) payload.get("key_points")).containsKey("能量"))
                .verifyComplete();
    }
}
