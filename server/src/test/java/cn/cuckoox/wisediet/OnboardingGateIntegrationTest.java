package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.test.StepVerifier;

class OnboardingGateIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private SessionStore sessionStore;

    @Test
    void shouldBlockNonOnboardingWhenStepIncomplete() {
        Mono<Void> flow = userRepository.save(new User(null, "u@a.com", "google", "gid", 1))
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(token -> sessionStore.saveSession(
                                        jwtService.extractJti(token),
                                        user.getId(),
                                        Duration.ofMinutes(15))
                                .then(Mono.<Void>fromRunnable(() ->
                                        webTestClient.get().uri("/api/secure/ping")
                                                .header("Authorization", "Bearer " + token)
                                                .exchange()
                                                .expectStatus().isForbidden()
                                ).subscribeOn(Schedulers.boundedElastic()))
                        )
                );

        StepVerifier.create(flow)
                .verifyComplete();
    }
}
