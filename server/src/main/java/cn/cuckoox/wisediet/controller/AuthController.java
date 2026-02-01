package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.controller.dto.AuthTokenResponse;
import cn.cuckoox.wisediet.controller.dto.AuthUriResponse;
import cn.cuckoox.wisediet.controller.dto.OAuthLoginRequest;
import cn.cuckoox.wisediet.service.OAuthService;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final OAuthService oauthService;

    public AuthController(OAuthService oauthService) {
        this.oauthService = oauthService;
    }

    @PostMapping("/{authType}")
    public Mono<AuthTokenResponse> auth(@PathVariable("authType") String type, @RequestBody OAuthLoginRequest request) {
        return oauthService.login(type, request.code(), request.state());
    }

    /**
     * 返回state以及认证参数
     *
     * @param type google/github
     * @return state/clientId
     */
    @GetMapping("/{authType}")
    public Mono<AuthUriResponse> getAuthUri(@PathVariable("authType") String type) {
        return oauthService.getAuthUri(type);
    }
}
