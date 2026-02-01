package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.controller.dto.AdminRevokeRequest;
import cn.cuckoox.wisediet.repository.AdminWhitelistRepository;
import cn.cuckoox.wisediet.service.SessionStore;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/admin/sessions")
public class AdminSessionController {

    private final AdminWhitelistRepository adminWhitelistRepository;
    private final SessionStore sessionStore;

    public AdminSessionController(AdminWhitelistRepository adminWhitelistRepository, SessionStore sessionStore) {
        this.adminWhitelistRepository = adminWhitelistRepository;
        this.sessionStore = sessionStore;
    }

    @PostMapping("/revoke")
    public Mono<Void> revoke(@RequestBody AdminRevokeRequest request) {
        return ReactiveSecurityContextHolder.getContext()
                .map(context -> context.getAuthentication())
                .flatMap(this::validateAdmin)
                .then(sessionStore.revokeUserSessions(request.userId()));
    }

    private Mono<Void> validateAdmin(Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return Mono.error(new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        }
        Long userId = (Long) authentication.getPrincipal();
        return adminWhitelistRepository.findByUserId(userId)
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.FORBIDDEN)))
                .then();
    }
}
