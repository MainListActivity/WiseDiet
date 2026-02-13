# OAuth State CSRF Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix OAuth CSRF vulnerability by storing and validating the `state` parameter in Redis.

**Architecture:** Add `saveOAuthState`/`validateAndConsumeOAuthState` to the existing `SessionStore`, modify `OAuthService` to store state on URI generation and validate+consume it on login callback. Use `ResponseStatusException(401)` for invalid state, consistent with the project's existing error handling pattern.

**Tech Stack:** Spring WebFlux, Spring Data Redis Reactive, Reactor, JUnit 5 + Reactor Test + Testcontainers

---

### Task 1: SessionStore — saveOAuthState

**Files:**
- Test: `server/src/test/java/cn/cuckoox/wisediet/SessionStoreIntegrationTest.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/service/SessionStore.java`

**Step 1: Write the failing test**

Add to `SessionStoreIntegrationTest.java`:

```java
@Test
void shouldSaveAndFindOAuthState() {
    Mono<Boolean> flow = sessionStore.saveOAuthState("test-state-123")
            .then(sessionStore.validateAndConsumeOAuthState("test-state-123"));

    StepVerifier.create(flow)
            .expectNext(true)
            .verifyComplete();
}
```

**Step 2: Run test to verify it fails**

Run: `cd server && ./mvnw test -pl . -Dtest="SessionStoreIntegrationTest#shouldSaveAndFindOAuthState" -Dsurefire.timeout=120`
Expected: FAIL — `saveOAuthState` method does not exist.

**Step 3: Implement saveOAuthState in SessionStore**

Add to `SessionStore.java`:

```java
private static final Duration OAUTH_STATE_TTL = Duration.ofMinutes(5);

public Mono<Boolean> saveOAuthState(String state) {
    return redisTemplate.opsForValue()
            .set(oauthStateKey(state), "1", OAUTH_STATE_TTL);
}

public Mono<Boolean> validateAndConsumeOAuthState(String state) {
    return redisTemplate.delete(oauthStateKey(state))
            .map(deleted -> deleted > 0);
}

private String oauthStateKey(String state) {
    return "oauth:state:" + state;
}
```

Note: `validateAndConsumeOAuthState` uses `delete` which is atomic — returns count of deleted keys (1 if existed, 0 if not). This is both validation and consumption in one atomic operation, preventing race conditions.

**Step 4: Run test to verify it passes**

Run: `cd server && ./mvnw test -pl . -Dtest="SessionStoreIntegrationTest#shouldSaveAndFindOAuthState" -Dsurefire.timeout=120`
Expected: PASS

**Step 5: Commit**

```bash
cd server && git add src/test/java/cn/cuckoox/wisediet/SessionStoreIntegrationTest.java src/main/java/cn/cuckoox/wisediet/service/SessionStore.java
git commit -m "feat: add OAuth state storage and validation to SessionStore"
```

---

### Task 2: SessionStore — validateAndConsumeOAuthState rejects unknown state

**Files:**
- Test: `server/src/test/java/cn/cuckoox/wisediet/SessionStoreIntegrationTest.java`

**Step 1: Write the failing test**

Add to `SessionStoreIntegrationTest.java`:

```java
@Test
void shouldRejectUnknownOAuthState() {
    StepVerifier.create(sessionStore.validateAndConsumeOAuthState("never-stored"))
            .expectNext(false)
            .verifyComplete();
}
```

**Step 2: Run test to verify it passes (already implemented)**

Run: `cd server && ./mvnw test -pl . -Dtest="SessionStoreIntegrationTest#shouldRejectUnknownOAuthState" -Dsurefire.timeout=120`
Expected: PASS — the `delete` returning 0 already maps to `false`.

**Step 3: Write one-time-use test**

Add to `SessionStoreIntegrationTest.java`:

```java
@Test
void shouldConsumeOAuthStateOnlyOnce() {
    Mono<Boolean> flow = sessionStore.saveOAuthState("once-state")
            .then(sessionStore.validateAndConsumeOAuthState("once-state"))
            .flatMap(first -> sessionStore.validateAndConsumeOAuthState("once-state"));

    StepVerifier.create(flow)
            .expectNext(false)
            .verifyComplete();
}
```

**Step 4: Run test to verify it passes**

Run: `cd server && ./mvnw test -pl . -Dtest="SessionStoreIntegrationTest#shouldConsumeOAuthStateOnlyOnce" -Dsurefire.timeout=120`
Expected: PASS — second consume returns false because the key was deleted.

**Step 5: Commit**

```bash
cd server && git add src/test/java/cn/cuckoox/wisediet/SessionStoreIntegrationTest.java
git commit -m "test: add OAuth state rejection and one-time-use tests"
```

---

### Task 3: OAuthService.getAuthUri — store state in Redis

**Files:**
- Test: `server/src/test/java/cn/cuckoox/wisediet/AuthControllerIntegrationTest.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/service/OAuthService.java`

**Step 1: Write the failing integration test**

Add to `AuthControllerIntegrationTest.java`:

```java
@Autowired
private SessionStore sessionStore;

@Test
void shouldStoreStateInRedisWhenGeneratingAuthUri() {
    webTestClient.get().uri("/api/auth/google")
            .exchange()
            .expectStatus().isOk()
            .expectBody()
            .jsonPath("$.state").value(state -> {
                StepVerifier.create(sessionStore.validateAndConsumeOAuthState((String) state))
                        .expectNext(true)
                        .verifyComplete();
            });
}
```

**Step 2: Run test to verify it fails**

Run: `cd server && ./mvnw test -pl . -Dtest="AuthControllerIntegrationTest#shouldStoreStateInRedisWhenGeneratingAuthUri" -Dsurefire.timeout=120`
Expected: FAIL — `validateAndConsumeOAuthState` returns false because `getAuthUri` doesn't store state in Redis yet.

**Step 3: Modify OAuthService.getAuthUri to store state**

In `OAuthService.java`, change `getAuthUri` from:

```java
public Mono<AuthUriResponse> getAuthUri(String authType) {
    return clientRegistrationRepository.findByRegistrationId(authType)
            .map(registration -> {
                String state = UUID.randomUUID().toString();
                String authorizationUri = org.springframework.web.util.UriComponentsBuilder.fromUriString(registration.getProviderDetails().getAuthorizationUri())
                        .queryParam("response_type", "code")
                        .queryParam("client_id", registration.getClientId())
                        .queryParam("scope", String.join(" ", registration.getScopes()))
                        .queryParam("state", state)
                        .build().toUriString();

                return new AuthUriResponse(authorizationUri, state, registration.getClientId(), registration.getRedirectUri(), registration.getScopes());
            });
}
```

To:

```java
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
```

Key change: `.map()` → `.flatMap()`, and `saveOAuthState(state).thenReturn(response)` at the end.

**Step 4: Run test to verify it passes**

Run: `cd server && ./mvnw test -pl . -Dtest="AuthControllerIntegrationTest#shouldStoreStateInRedisWhenGeneratingAuthUri" -Dsurefire.timeout=120`
Expected: PASS

**Step 5: Commit**

```bash
cd server && git add src/test/java/cn/cuckoox/wisediet/AuthControllerIntegrationTest.java src/main/java/cn/cuckoox/wisediet/service/OAuthService.java
git commit -m "feat: store OAuth state in Redis when generating auth URI"
```

---

### Task 4: OAuthService.login — validate state before token exchange

**Files:**
- Test: `server/src/test/java/cn/cuckoox/wisediet/AuthControllerIntegrationTest.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/service/OAuthService.java`

**Step 1: Write the failing test — reject invalid state**

Add to `AuthControllerIntegrationTest.java`:

```java
@Test
void shouldRejectLoginWithInvalidState() {
    webTestClient.post().uri("/api/auth/google")
            .bodyValue(new OAuthLoginRequest("code-123", "invalid-state"))
            .exchange()
            .expectStatus().isUnauthorized();
}
```

**Step 2: Run test to verify it fails**

Run: `cd server && ./mvnw test -pl . -Dtest="AuthControllerIntegrationTest#shouldRejectLoginWithInvalidState" -Dsurefire.timeout=120`
Expected: FAIL — currently returns 200 because state is never validated.

**Step 3: Modify OAuthService.login to validate state**

In `OAuthService.java`, change the `login` method. Wrap the existing logic with state validation:

```java
public Mono<AuthTokenResponse> login(String registrationId, String code, String state) {
    return sessionStore.validateAndConsumeOAuthState(state)
            .flatMap(valid -> {
                if (!valid) {
                    return Mono.error(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid or expired OAuth state"));
                }
                return clientRegistrationRepository.findByRegistrationId(registrationId);
            })
            .flatMap(registration -> {
                // ... rest of existing token exchange logic unchanged
```

Full replacement for the `login` method:

```java
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
                String providerId = oauth2User.getName();

                if (email == null) {
                    return Mono.error(new IllegalStateException("Email not found in OAuth2 user info"));
                }

                return userRepository.save(new User(
                        null,
                        email,
                        registrationId,
                        providerId,
                        1));
            })
            .flatMap(user -> jwtService.createAccessToken(user.getId())
                    .flatMap(accessToken -> sessionStore.saveSession(
                                    jwtService.extractJti(accessToken),
                                    user.getId(),
                                    Duration.ofMinutes(15))
                            .thenReturn(new AuthTokenResponse(accessToken, UUID.randomUUID().toString()))));
}
```

Add import at the top of `OAuthService.java`:

```java
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
```

**Step 4: Run test to verify it passes**

Run: `cd server && ./mvnw test -pl . -Dtest="AuthControllerIntegrationTest#shouldRejectLoginWithInvalidState" -Dsurefire.timeout=120`
Expected: PASS — returns 401 for unknown state.

**Step 5: Commit**

```bash
cd server && git add src/test/java/cn/cuckoox/wisediet/AuthControllerIntegrationTest.java src/main/java/cn/cuckoox/wisediet/service/OAuthService.java
git commit -m "feat: validate and consume OAuth state on login to prevent CSRF"
```

---

### Task 5: Fix existing test and add full-flow integration test

**Files:**
- Modify: `server/src/test/java/cn/cuckoox/wisediet/AuthControllerIntegrationTest.java`

**Step 1: Fix the existing `shouldReturnTokensForGoogleLogin` test**

The existing test uses a hardcoded `"state-123"` that is not stored in Redis. It will now fail because login validates state. Fix it by pre-storing the state:

```java
@Test
void shouldReturnTokensForGoogleLogin() {
    String state = "state-123";
    // Pre-store the state in Redis so login validation passes
    StepVerifier.create(sessionStore.saveOAuthState(state))
            .expectNext(true)
            .verifyComplete();

    webTestClient.post().uri("/api/auth/google")
            .bodyValue(new OAuthLoginRequest("code-123", state))
            .exchange()
            .expectStatus().isOk()
            .expectBody()
            .jsonPath("$.accessToken").exists()
            .jsonPath("$.refreshToken").exists();
}
```

**Step 2: Add full end-to-end flow test (getAuthUri → login)**

```java
@Test
void shouldCompleteFullOAuthFlowWithStateValidation() {
    // Step 1: Get auth URI (state gets stored in Redis)
    String state = webTestClient.get().uri("/api/auth/google")
            .exchange()
            .expectStatus().isOk()
            .expectBody()
            .jsonPath("$.state").exists()
            .returnResult()
            .getResponseBody() != null ?
            new String(webTestClient.get().uri("/api/auth/google")
                    .exchange()
                    .expectBody()
                    .jsonPath("$.state").exists()
                    .returnResult()
                    .getResponseBody()) : null;

    // Better approach: extract state from response
    webTestClient.get().uri("/api/auth/google")
            .exchange()
            .expectStatus().isOk()
            .expectBody()
            .jsonPath("$.state").value(stateValue -> {
                // Step 2: Use the state from getAuthUri to login
                webTestClient.post().uri("/api/auth/google")
                        .bodyValue(new OAuthLoginRequest("code-123", (String) stateValue))
                        .exchange()
                        .expectStatus().isOk()
                        .expectBody()
                        .jsonPath("$.accessToken").exists()
                        .jsonPath("$.refreshToken").exists();
            });
}
```

NOTE: The nested WebTestClient approach above can be tricky. A cleaner approach using `WebTestClient.returnResult()`:

```java
@Test
void shouldCompleteFullOAuthFlowWithStateValidation() {
    // Step 1: Get auth URI — state gets stored in Redis
    byte[] body = webTestClient.get().uri("/api/auth/google")
            .exchange()
            .expectStatus().isOk()
            .expectBody()
            .jsonPath("$.state").exists()
            .returnResult()
            .getResponseBody();

    String state = com.fasterxml.jackson.databind.ObjectMapper
            .readTree(body).get("state").asText();

    // Step 2: Login using the state from getAuthUri
    webTestClient.post().uri("/api/auth/google")
            .bodyValue(new OAuthLoginRequest("code-123", state))
            .exchange()
            .expectStatus().isOk()
            .expectBody()
            .jsonPath("$.accessToken").exists()
            .jsonPath("$.refreshToken").exists();
}
```

NOTE: Since `ObjectMapper.readTree` is static and throws a checked exception, use a field-injected or manually created ObjectMapper. Simplest approach — use a JsonPath library or just inject ObjectMapper:

```java
@Test
void shouldCompleteFullOAuthFlowWithStateValidation() throws Exception {
    com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();

    // Step 1: Get auth URI — state gets stored in Redis
    byte[] body = webTestClient.get().uri("/api/auth/google")
            .exchange()
            .expectStatus().isOk()
            .expectBody()
            .returnResult()
            .getResponseBody();

    String state = objectMapper.readTree(body).get("state").asText();

    // Step 2: Login using the state from getAuthUri
    webTestClient.post().uri("/api/auth/google")
            .bodyValue(new OAuthLoginRequest("code-123", state))
            .exchange()
            .expectStatus().isOk()
            .expectBody()
            .jsonPath("$.accessToken").exists()
            .jsonPath("$.refreshToken").exists();
}
```

**Step 3: Run all AuthController tests**

Run: `cd server && ./mvnw test -pl . -Dtest="AuthControllerIntegrationTest" -Dsurefire.timeout=120`
Expected: ALL PASS

**Step 4: Run full test suite**

Run: `cd server && ./mvnw test -Dsurefire.timeout=120`
Expected: ALL PASS

**Step 5: Commit**

```bash
cd server && git add src/test/java/cn/cuckoox/wisediet/AuthControllerIntegrationTest.java
git commit -m "test: fix existing OAuth test and add full-flow state validation test"
```
