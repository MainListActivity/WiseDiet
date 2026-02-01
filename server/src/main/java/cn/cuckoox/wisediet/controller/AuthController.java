package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.controller.dto.AuthTokenResponse;
import cn.cuckoox.wisediet.controller.dto.OAuthLoginRequest;
import cn.cuckoox.wisediet.service.OAuthService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final OAuthService oauthService;

    public AuthController(OAuthService oauthService) {
        this.oauthService = oauthService;
    }

    @PostMapping("/google")
    public Mono<AuthTokenResponse> google(@RequestBody OAuthLoginRequest request) {
        return oauthService.login("google", request.code());
    }

    @PostMapping("/github")
    public Mono<AuthTokenResponse> github(@RequestBody OAuthLoginRequest request) {
        return oauthService.login("github", request.code());
    }
}
