package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.UserProfile;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class SecurityBoundaryIntegrationTest extends AbstractIntegrationTest {

    @Test
    void shouldRequireAuthenticationForOnboardingProfile() {
        UserProfile request = new UserProfile(null, "Male", 28, 180.0, 70.0, "1", 2);

        Mono<Boolean> flow = Mono.fromCallable(() -> {
            webTestClient.post()
                    .uri("/api/onboarding/profile")
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isUnauthorized();
            return true;
        });

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldAllowAnonymousAccessForOccupationTags() {
        Mono<Boolean> flow = Mono.fromCallable(() -> {
            webTestClient.get()
                    .uri("/api/tags/occupations")
                    .exchange()
                    .expectStatus().isOk();
            return true;
        });

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldRequireAuthenticationForAdminSessionRevoke() {
        Mono<Boolean> flow = Mono.fromCallable(() -> {
            webTestClient.post()
                    .uri("/api/admin/sessions/revoke")
                    .bodyValue(new cn.cuckoox.wisediet.controller.dto.AdminRevokeRequest(1L))
                    .exchange()
                    .expectStatus().isUnauthorized();
            return true;
        });

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }
}
