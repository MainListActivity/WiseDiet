package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.controller.dto.AdminRevokeRequest;
import cn.cuckoox.wisediet.model.AdminWhitelist;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.AdminWhitelistRepository;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.test.StepVerifier;

class CurrentUserSessionFlowIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AdminWhitelistRepository adminWhitelistRepository;

    @Autowired
    private SessionStore sessionStore;

    @Autowired
    private JwtService jwtService;

    @Test
    void shouldAllowAdminRevokeWhenTokenAndSessionBelongToSameUser() {
        Mono<Boolean> flow = userRepository.save(new User(null, "admin-flow@a.com", "google", "aid-flow", 0))
                .flatMap(admin -> adminWhitelistRepository.save(new AdminWhitelist(null, admin.getId()))
                        .then(userRepository.save(new User(null, "target-flow@a.com", "google", "tid-flow", 0)))
                        .flatMap(target -> jwtService.createAccessToken(admin.getId())
                                .flatMap(adminToken -> sessionStore.saveSession(
                                                jwtService.extractJti(adminToken),
                                                admin.getId(),
                                                Duration.ofMinutes(15))
                                        .then(Mono.fromRunnable(() -> {
                                            webTestClient.post()
                                                    .uri("/api/admin/sessions/revoke")
                                                    .header("Authorization", "Bearer " + adminToken)
                                                    .bodyValue(new AdminRevokeRequest(target.getId()))
                                                    .exchange()
                                                    .expectStatus().isOk();
                                        }).subscribeOn(Schedulers.boundedElastic()).thenReturn(true))
                                )));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldRejectWhenTokenUserDoesNotMatchSessionUser() {
        Mono<Boolean> flow = userRepository.save(new User(null, "admin-mismatch@a.com", "google", "aid-mismatch", 0))
                .flatMap(admin -> adminWhitelistRepository.save(new AdminWhitelist(null, admin.getId()))
                        .then(userRepository.save(new User(null, "other-mismatch@a.com", "google", "oid-mismatch", 0)))
                        .flatMap(otherUser -> jwtService.createAccessToken(admin.getId())
                                .flatMap(adminToken -> sessionStore.saveSession(
                                                jwtService.extractJti(adminToken),
                                                otherUser.getId(),
                                                Duration.ofMinutes(15))
                                        .then(Mono.fromRunnable(() -> {
                                            webTestClient.post()
                                                    .uri("/api/admin/sessions/revoke")
                                                    .header("Authorization", "Bearer " + adminToken)
                                                    .bodyValue(new AdminRevokeRequest(otherUser.getId()))
                                                    .exchange()
                                                    .expectStatus().isUnauthorized();
                                        }).subscribeOn(Schedulers.boundedElastic()).thenReturn(true))
                                )));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }
}
