package cn.cuckoox.wisediet.service;

import cn.cuckoox.wisediet.controller.dto.AuthTokenResponse;
import cn.cuckoox.wisediet.controller.dto.AuthUriResponse;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.UserRepository;
import java.time.Duration;
import java.util.UUID;
import org.springframework.security.oauth2.client.endpoint.OAuth2AuthorizationCodeGrantRequest;
import org.springframework.security.oauth2.client.endpoint.WebClientReactiveAuthorizationCodeTokenResponseClient;
import org.springframework.security.oauth2.client.registration.ReactiveClientRegistrationRepository;
import org.springframework.security.oauth2.client.userinfo.DefaultReactiveOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.endpoint.OAuth2AuthorizationExchange;
import org.springframework.security.oauth2.core.endpoint.OAuth2AuthorizationRequest;
import org.springframework.security.oauth2.core.endpoint.OAuth2AuthorizationResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

@Service
public class OAuthService {

    private final ReactiveClientRegistrationRepository clientRegistrationRepository;
    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final SessionStore sessionStore;
    private final WebClientReactiveAuthorizationCodeTokenResponseClient tokenResponseClient;
    private final DefaultReactiveOAuth2UserService oauth2UserService;

    public OAuthService(ReactiveClientRegistrationRepository clientRegistrationRepository,
                        UserRepository userRepository,
                        JwtService jwtService,
                        SessionStore sessionStore) {
        this.clientRegistrationRepository = clientRegistrationRepository;
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.sessionStore = sessionStore;
        this.tokenResponseClient = new WebClientReactiveAuthorizationCodeTokenResponseClient();
        this.oauth2UserService = new DefaultReactiveOAuth2UserService();
    }

    public Mono<AuthTokenResponse> login(String registrationId, String code, String state) {
        return sessionStore.validateAndConsumeOAuthState(state)
                .flatMap(valid -> {
                    if (!valid) {
                        return Mono.error(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid or expired OAuth state"));
                    }
                    return clientRegistrationRepository.findByRegistrationId(registrationId);
                })
                .flatMap(registration -> {
                    OAuth2AuthorizationRequest authorizationRequest = OAuth2AuthorizationRequest.authorizationCode()
                            .clientId(registration.getClientId())
                            .authorizationUri(registration.getProviderDetails().getAuthorizationUri())
                            .redirectUri(registration.getRedirectUri())
                            .scopes(registration.getScopes())
                            .state(state)
                            .build();

                    OAuth2AuthorizationResponse authorizationResponse = OAuth2AuthorizationResponse.success(code)
                            .redirectUri(registration.getRedirectUri())
                            .state(state)
                            .build();

                    OAuth2AuthorizationExchange exchange = new OAuth2AuthorizationExchange(authorizationRequest, authorizationResponse);
                    OAuth2AuthorizationCodeGrantRequest tokenRequest = new OAuth2AuthorizationCodeGrantRequest(registration, exchange);

                    return tokenResponseClient.getTokenResponse(tokenRequest)
                            .flatMap(tokenResponse -> {
                                OAuth2UserRequest userRequest = new OAuth2UserRequest(registration, tokenResponse.getAccessToken());
                                return oauth2UserService.loadUser(userRequest);
                            });
                })
                .flatMap(oauth2User -> {
                    String email = oauth2User.getAttribute("email");
                    String providerId = oauth2User.getName(); // Default uses 'sub' or configured username attribute
                    
                    // Fallback or specific logic if needed for different providers
                    if (email == null) {
                        return Mono.error(new IllegalStateException("Email not found in OAuth2 user info"));
                    }

                    return userRepository.findByProviderAndProviderUserId(registrationId, providerId)
                            .switchIfEmpty(userRepository.save(new User(
                                    null,
                                    email,
                                    registrationId,
                                    providerId,
                                    1)));
                })
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(accessToken -> sessionStore.saveSession(
                                        jwtService.extractJti(accessToken),
                                        user.getId(),
                                        Duration.ofMinutes(15))
                                .thenReturn(new AuthTokenResponse(accessToken, UUID.randomUUID().toString()))));
    }

    public Mono<AuthUriResponse> getAuthUri(String authType) {
        return clientRegistrationRepository.findByRegistrationId(authType)
                .flatMap(registration -> {
                    String state = UUID.randomUUID().toString();
                    String authorizationUri = org.springframework.web.util.UriComponentsBuilder.fromUriString(registration.getProviderDetails().getAuthorizationUri())
                            .queryParam("response_type", "code")
                            .queryParam("client_id", registration.getClientId())
                            .queryParam("scope", String.join(" ", registration.getScopes()))
                            .queryParam("state", state)
                            .build().toUriString();

                    AuthUriResponse response = new AuthUriResponse(authorizationUri, state, registration.getClientId(), registration.getRedirectUri(), registration.getScopes());
                    return sessionStore.saveOAuthState(state).thenReturn(response);
                });
    }
}
