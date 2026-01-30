# Social Login + Stateful JWT + Onboarding Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement Google/GitHub login, stateful JWT validation via Redis, global onboarding gate, and admin session revocation.

**Architecture:** WebFlux backend issues JWTs and stores session state in Redis keyed by `jti`; a security filter validates JWT + Redis session and an onboarding gate restricts non-onboarding endpoints. Flutter client performs native Google Sign-In and GitHub OAuth via system browser + App Links.

**Tech Stack:** Spring Boot WebFlux + Spring Security + R2DBC + Redis Reactive, Flutter 3, Riverpod (if used), App Links/Universal Links, Google Sign-In.

---

### Task 1: Add user + admin whitelist schema and repositories

**Files:**
- Modify: `server/src/main/resources/schema.sql`
- Create: `server/src/main/java/cn/cuckoox/wisediet/model/User.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/model/AdminWhitelist.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/repository/UserRepository.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/repository/AdminWhitelistRepository.java`
- Test: `server/src/test/java/cn/cuckoox/wisediet/UserRepositoryIntegrationTest.java`

**Step 1: Write the failing test**
```java
@Test
void shouldPersistUserWithOnboardingStep() {
    Mono<User> saved = userRepository.save(new User(null, "a@b.com", "google", "gid", 1));
    StepVerifier.create(saved.flatMap(user -> userRepository.findById(user.getId())))
        .expectNextMatches(user -> user.getOnboardingStep() == 1)
        .verifyComplete();
}
```

**Step 2: Run test to verify it fails**
Run: `./mvnw -q -Dtest=UserRepositoryIntegrationTest test`
Expected: FAIL (missing table or class)

**Step 3: Write minimal implementation**
```java
@Table("users")
public class User { @Id Long id; String email; String provider; String providerUserId; Integer onboardingStep; }
```
Add schema:
```sql
CREATE TABLE IF NOT EXISTS "users" (...);
CREATE TABLE IF NOT EXISTS "admin_whitelist" (...);
```

**Step 4: Run test to verify it passes**
Run: `./mvnw -q -Dtest=UserRepositoryIntegrationTest test`
Expected: PASS

**Step 5: Commit**
```bash
git add server/src/main/resources/schema.sql \
  server/src/main/java/cn/cuckoox/wisediet/model/User.java \
  server/src/main/java/cn/cuckoox/wisediet/model/AdminWhitelist.java \
  server/src/main/java/cn/cuckoox/wisediet/repository/UserRepository.java \
  server/src/main/java/cn/cuckoox/wisediet/repository/AdminWhitelistRepository.java \
  server/src/test/java/cn/cuckoox/wisediet/UserRepositoryIntegrationTest.java
git commit -m "feat: add user and admin whitelist schema"
```

### Task 2: Add JWT config + token service

**Files:**
- Modify: `server/pom.xml`
- Create: `server/src/main/java/cn/cuckoox/wisediet/config/JwtProperties.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/service/JwtService.java`
- Test: `server/src/test/java/cn/cuckoox/wisediet/JwtServiceTest.java`

**Step 1: Write the failing test**
```java
@Test
void shouldCreateAndParseAccessToken() {
    Mono<String> tokenMono = jwtService.createAccessToken(42L);
    StepVerifier.create(tokenMono.flatMap(jwtService::parseUserId))
        .expectNext(42L)
        .verifyComplete();
}
```

**Step 2: Run test to verify it fails**
Run: `./mvnw -q -Dtest=JwtServiceTest test`
Expected: FAIL (missing JwtService)

**Step 3: Write minimal implementation**
- Add dependency: `spring-security-oauth2-jose`.
- `JwtProperties` with `secret`, `accessTtlMinutes=15`, `refreshTtlDays=30`.
- `JwtService` uses HMAC to sign JWTs and returns `Mono<String>`.

**Step 4: Run test to verify it passes**
Run: `./mvnw -q -Dtest=JwtServiceTest test`
Expected: PASS

**Step 5: Commit**
```bash
git add server/pom.xml \
  server/src/main/java/cn/cuckoox/wisediet/config/JwtProperties.java \
  server/src/main/java/cn/cuckoox/wisediet/service/JwtService.java \
  server/src/test/java/cn/cuckoox/wisediet/JwtServiceTest.java
git commit -m "feat: add jwt config and service"
```

### Task 3: Redis session store (stateful JWT)

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/service/SessionStore.java`
- Test: `server/src/test/java/cn/cuckoox/wisediet/SessionStoreIntegrationTest.java`

**Step 1: Write the failing test**
```java
@Test
void shouldSaveAndFindSession() {
    Mono<Boolean> saved = sessionStore.saveSession("jti-1", 42L, Duration.ofMinutes(15));
    StepVerifier.create(saved.then(sessionStore.exists("jti-1")))
        .expectNext(true)
        .verifyComplete();
}
```

**Step 2: Run test to verify it fails**
Run: `./mvnw -q -Dtest=SessionStoreIntegrationTest test`
Expected: FAIL (missing bean)

**Step 3: Write minimal implementation**
- Use `ReactiveStringRedisTemplate`.
- Keys: `session:{jti}` and `user:{userId}:sessions` (set).
- `saveSession`, `exists`, `revokeUserSessions(userId)`.

**Step 4: Run test to verify it passes**
Run: `./mvnw -q -Dtest=SessionStoreIntegrationTest test`
Expected: PASS

**Step 5: Commit**
```bash
git add server/src/main/java/cn/cuckoox/wisediet/service/SessionStore.java \
  server/src/test/java/cn/cuckoox/wisediet/SessionStoreIntegrationTest.java
git commit -m "feat: add redis-backed session store"
```

### Task 4: JWT + Redis authentication filter

**Files:**
- Modify: `server/src/main/java/cn/cuckoox/wisediet/config/SecurityConfig.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/security/JwtAuthenticationFilter.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/SecurePingController.java`
- Test: `server/src/test/java/cn/cuckoox/wisediet/AuthFilterIntegrationTest.java`

**Step 1: Write the failing test**
```java
@Test
void shouldRejectMissingRedisSession() {
    Mono<Void> flow = jwtService.createAccessToken(42L)
        .flatMap(token -> Mono.fromRunnable(() ->
            webTestClient.get().uri("/api/secure/ping")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isUnauthorized()
        ));

    StepVerifier.create(flow).verifyComplete();
}
```

**Step 2: Run test to verify it fails**
Run: `./mvnw -q -Dtest=AuthFilterIntegrationTest test`
Expected: FAIL (endpoint not secured)

**Step 3: Write minimal implementation**
- Filter validates JWT signature and checks Redis `session:{jti}` exists.
- On success, set `Authentication` with `userId` as principal.
- Secure `/api/secure/**` in `SecurityConfig`.

**Step 4: Run test to verify it passes**
Run: `./mvnw -q -Dtest=AuthFilterIntegrationTest test`
Expected: PASS

**Step 5: Commit**
```bash
git add server/src/main/java/cn/cuckoox/wisediet/config/SecurityConfig.java \
  server/src/main/java/cn/cuckoox/wisediet/security/JwtAuthenticationFilter.java \
  server/src/main/java/cn/cuckoox/wisediet/controller/SecurePingController.java \
  server/src/test/java/cn/cuckoox/wisediet/AuthFilterIntegrationTest.java
git commit -m "feat: enforce jwt + redis auth on secure endpoints"
```

### Task 5: Global onboarding gate

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/security/OnboardingGateFilter.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/config/SecurityConfig.java`
- Test: `server/src/test/java/cn/cuckoox/wisediet/OnboardingGateIntegrationTest.java`

**Step 1: Write the failing test**
```java
@Test
void shouldBlockNonOnboardingWhenStepIncomplete() {
    Mono<Void> flow = userRepository.save(new User(null, "u@a.com", "google", "gid", 1))
        .flatMap(user -> jwtService.createAccessToken(user.getId())
            .flatMap(token -> sessionStore.saveSession(jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                .then(Mono.fromRunnable(() ->
                    webTestClient.get().uri("/api/secure/ping")
                        .header("Authorization", "Bearer " + token)
                        .exchange()
                        .expectStatus().isForbidden()
                ))
            )
        );

    StepVerifier.create(flow).verifyComplete();
}
```

**Step 2: Run test to verify it fails**
Run: `./mvnw -q -Dtest=OnboardingGateIntegrationTest test`
Expected: FAIL (no gate)

**Step 3: Write minimal implementation**
- Gate reads `userId` from authentication, loads user reactively.
- If `onboardingStep > 0` and path not under `/auth/**` or `/api/onboarding/**`, return 403 with `ONBOARDING_REQUIRED`.

**Step 4: Run test to verify it passes**
Run: `./mvnw -q -Dtest=OnboardingGateIntegrationTest test`
Expected: PASS

**Step 5: Commit**
```bash
git add server/src/main/java/cn/cuckoox/wisediet/security/OnboardingGateFilter.java \
  server/src/main/java/cn/cuckoox/wisediet/config/SecurityConfig.java \
  server/src/test/java/cn/cuckoox/wisediet/OnboardingGateIntegrationTest.java
git commit -m "feat: add onboarding gate"
```

### Task 6: Admin revoke endpoint

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/AdminSessionController.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/dto/AdminRevokeRequest.java`
- Test: `server/src/test/java/cn/cuckoox/wisediet/AdminRevokeIntegrationTest.java`

**Step 1: Write the failing test**
```java
@Test
void adminCanRevokeAllUserSessions() {
    Mono<Void> flow = userRepository.save(new User(null, "admin@a.com", "google", "aid", 0))
        .flatMap(admin -> adminWhitelistRepository.save(new AdminWhitelist(null, admin.getId()))
            .then(userRepository.save(new User(null, "t@a.com", "google", "tid", 0)))
            .flatMap(target -> sessionStore.saveSession("jti-1", target.getId(), Duration.ofMinutes(15))
                .then(jwtService.createAccessToken(admin.getId()))
                .flatMap(adminToken -> Mono.fromRunnable(() ->
                    webTestClient.post().uri("/api/admin/sessions/revoke")
                        .header("Authorization", "Bearer " + adminToken)
                        .bodyValue(new AdminRevokeRequest(target.getId()))
                        .exchange()
                        .expectStatus().isOk()
                ))
                .then(sessionStore.exists("jti-1"))
                .flatMap(exists -> {
                    if (exists) return Mono.error(new IllegalStateException("session not revoked"));
                    return Mono.empty();
                })
            )
        );

    StepVerifier.create(flow).verifyComplete();
}
```

**Step 2: Run test to verify it fails**
Run: `./mvnw -q -Dtest=AdminRevokeIntegrationTest test`
Expected: FAIL (endpoint missing)

**Step 3: Write minimal implementation**
- Endpoint checks caller userId in `admin_whitelist`.
- Calls `sessionStore.revokeUserSessions(targetUserId)`.

**Step 4: Run test to verify it passes**
Run: `./mvnw -q -Dtest=AdminRevokeIntegrationTest test`
Expected: PASS

**Step 5: Commit**
```bash
git add server/src/main/java/cn/cuckoox/wisediet/controller/AdminSessionController.java \
  server/src/main/java/cn/cuckoox/wisediet/controller/dto/AdminRevokeRequest.java \
  server/src/test/java/cn/cuckoox/wisediet/AdminRevokeIntegrationTest.java
git commit -m "feat: add admin session revoke"
```

### Task 7: OAuth endpoints (Google/GitHub)

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/AuthController.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/service/OAuthClient.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/service/OAuthService.java`
- Test: `server/src/test/java/cn/cuckoox/wisediet/AuthControllerIntegrationTest.java`

**Step 1: Write the failing test**
```java
@Test
void shouldReturnTokensForGoogleLogin() {
    webTestClient.post().uri("/api/auth/google")
        .bodyValue(new OAuthLoginRequest("code-123"))
        .exchange()
        .expectStatus().isOk()
        .expectBody()
        .jsonPath("$.accessToken").exists()
        .jsonPath("$.refreshToken").exists();
}
```

**Step 2: Run test to verify it fails**
Run: `./mvnw -q -Dtest=AuthControllerIntegrationTest test`
Expected: FAIL (controller missing)

**Step 3: Write minimal implementation**
- `OAuthClient` interface for exchanging code and fetching profile.
- `OAuthService` maps profile to user, sets `onboardingStep=1` for new user, issues tokens, stores sessions.
- In tests, provide a `@TestConfiguration` bean for `OAuthClient` returning deterministic profile.

**Step 4: Run test to verify it passes**
Run: `./mvnw -q -Dtest=AuthControllerIntegrationTest test`
Expected: PASS

**Step 5: Commit**
```bash
git add server/src/main/java/cn/cuckoox/wisediet/controller/AuthController.java \
  server/src/main/java/cn/cuckoox/wisediet/service/OAuthClient.java \
  server/src/main/java/cn/cuckoox/wisediet/service/OAuthService.java \
  server/src/test/java/cn/cuckoox/wisediet/AuthControllerIntegrationTest.java
git commit -m "feat: add google/github auth endpoints"
```

### Task 8: Flutter auth state + login screen

**Files:**
- Create: `client/lib/features/auth/auth_state.dart`
- Create: `client/lib/features/auth/login_screen.dart`
- Modify: `client/lib/app/router.dart`
- Test: `client/test/auth_state_test.dart`

**Step 1: Write the failing test**
```dart
void main() {
  test('starts logged out', () {
    final state = AuthState.initial();
    expect(state.isLoggedIn, false);
  });
}
```

**Step 2: Run test to verify it fails**
Run: `flutter test test/auth_state_test.dart`
Expected: FAIL (missing AuthState)

**Step 3: Write minimal implementation**
- `AuthState` with `isLoggedIn`, `onboardingStep`, `accessToken`, `refreshToken`.
- `LoginScreen` with Google/GitHub buttons (no wiring yet).
- Router guard: if not logged in → login; if onboardingStep > 0 → onboarding.

**Step 4: Run test to verify it passes**
Run: `flutter test test/auth_state_test.dart`
Expected: PASS

**Step 5: Commit**
```bash
git add client/lib/features/auth/auth_state.dart \
  client/lib/features/auth/login_screen.dart \
  client/lib/app/router.dart \
  client/test/auth_state_test.dart
git commit -m "feat: add auth state and login screen"
```

### Task 9: Flutter Google + GitHub login wiring

**Files:**
- Modify: `client/pubspec.yaml`
- Create: `client/lib/features/auth/google_login.dart`
- Create: `client/lib/features/auth/github_login.dart`
- Modify: `client/lib/features/auth/auth_controller.dart`
- Test: `client/test/auth_controller_test.dart`

**Step 1: Write the failing test**
```dart
void main() {
  test('login success updates state', () async {
    final controller = AuthController(fakeAuthApi);
    await controller.loginWithGoogle();
    expect(controller.state.isLoggedIn, true);
  });
}
```

**Step 2: Run test to verify it fails**
Run: `flutter test test/auth_controller_test.dart`
Expected: FAIL (missing controller)

**Step 3: Write minimal implementation**
- Add dependencies: `google_sign_in`, `flutter_secure_storage`, `app_links`.
- Google: get auth code, call backend `/api/auth/google`.
- GitHub: launch system browser to backend `/api/auth/github`, handle App Link callback, complete login.
- Store tokens securely, update `AuthState`.

**Step 4: Run test to verify it passes**
Run: `flutter test test/auth_controller_test.dart`
Expected: PASS

**Step 5: Commit**
```bash
git add client/pubspec.yaml \
  client/lib/features/auth/google_login.dart \
  client/lib/features/auth/github_login.dart \
  client/lib/features/auth/auth_controller.dart \
  client/test/auth_controller_test.dart
git commit -m "feat: wire google/github login"
```

### Task 10: Client handling for kick-out and onboarding

**Files:**
- Modify: `client/lib/core/network/api_client.dart`
- Modify: `client/lib/features/auth/auth_controller.dart`
- Test: `client/test/auth_kickout_test.dart`

**Step 1: Write the failing test**
```dart
void main() {
  test('kick-out clears tokens and shows message', () async {
    final controller = AuthController(fakeAuthApi);
    await controller.handleUnauthorized();
    expect(controller.state.isLoggedIn, false);
  });
}
```

**Step 2: Run test to verify it fails**
Run: `flutter test test/auth_kickout_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**
- On 401 from API client: clear tokens, set logged out, show "账号暂不可用，稍后重试".
- On 403 `ONBOARDING_REQUIRED`: route to onboarding.

**Step 4: Run test to verify it passes**
Run: `flutter test test/auth_kickout_test.dart`
Expected: PASS

**Step 5: Commit**
```bash
git add client/lib/core/network/api_client.dart \
  client/lib/features/auth/auth_controller.dart \
  client/test/auth_kickout_test.dart
git commit -m "feat: handle kick-out and onboarding routing"
```

---

## Notes
- All backend tests must use `StepVerifier.create().expectNext().verifyComplete()` and avoid `.block()` in reactive flows.
- Keep each code change under ~150 lines; split tasks further if needed during execution.
