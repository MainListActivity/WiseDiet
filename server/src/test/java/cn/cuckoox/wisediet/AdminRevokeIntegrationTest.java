package cn.cuckoox.wisediet;

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

class AdminRevokeIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AdminWhitelistRepository adminWhitelistRepository;

    @Autowired
    private SessionStore sessionStore;

    @Autowired
    private JwtService jwtService;

    @Test
    void adminCanRevokeAllUserSessions() {
        Mono<Void> flow = userRepository.save(new User(null, "admin@a.com", "google", "aid", 0))
                .flatMap(admin -> adminWhitelistRepository.save(new AdminWhitelist(null, admin.getId()))
                        .then(userRepository.save(new User(null, "t@a.com", "google", "tid", 0)))
                        .flatMap(target -> sessionStore.saveSession("jti-1", target.getId(), Duration.ofMinutes(15))
                                .then(jwtService.createAccessToken(admin.getId()))
                                .flatMap(adminToken -> sessionStore.saveSession(
                                                jwtService.extractJti(adminToken),
                                                admin.getId(),
                                                Duration.ofMinutes(15))
                                        .then(Mono.<Void>fromRunnable(() ->
                                                webTestClient.post().uri("/api/admin/sessions/revoke")
                                                        .header("Authorization", "Bearer " + adminToken)
                                                        .bodyValue(new cn.cuckoox.wisediet.controller.dto.AdminRevokeRequest(target.getId()))
                                                        .exchange()
                                                        .expectStatus().isOk()
                                        ).subscribeOn(Schedulers.boundedElastic()))
                                )
                                .then(sessionStore.exists("jti-1"))
                                .flatMap(exists -> {
                                    if (exists) return Mono.error(new IllegalStateException("session not revoked"));
                                    return Mono.empty();
                                })
                        )
                );

        StepVerifier.create(flow)
                .verifyComplete();
    }
}
