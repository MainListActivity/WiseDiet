package cn.cuckoox.wisediet.service;

import cn.cuckoox.wisediet.controller.dto.AuthTokenResponse;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.UserRepository;
import java.time.Duration;
import java.util.UUID;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
public class OAuthService {

    private final OAuthClient oauthClient;
    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final SessionStore sessionStore;

    public OAuthService(OAuthClient oauthClient, UserRepository userRepository, JwtService jwtService, SessionStore sessionStore) {
        this.oauthClient = oauthClient;
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.sessionStore = sessionStore;
    }

    public Mono<AuthTokenResponse> login(String provider, String code) {
        return oauthClient.exchangeAndFetchProfile(provider, code)
                .flatMap(profile -> userRepository.save(new User(
                        null,
                        profile.email(),
                        profile.provider(),
                        profile.providerUserId(),
                        1)))
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(accessToken -> sessionStore.saveSession(
                                        jwtService.extractJti(accessToken),
                                        user.getId(),
                                        Duration.ofMinutes(15))
                                .thenReturn(new AuthTokenResponse(accessToken, UUID.randomUUID().toString()))));
    }
}
