# Onboarding 幂等性与重复引导修复 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复用户重新登录后被重复引导 onboarding、以及重复创建 profile 的两个问题。

**Architecture:** 后端登录响应新增 `onboardingStep` 字段（真相来源），前端读取该字段而非硬编码；后端 `saveProfile` 改为 upsert 并在成功后将 `onboarding_step` 置 0；数据库加唯一约束兜底。

**Tech Stack:** Spring Boot 4 WebFlux / R2DBC (backend), Flutter + Riverpod + GoRouter (frontend)

---

## Task 1：后端 — `AuthTokenResponse` 加 `onboardingStep` 字段

**Files:**
- Modify: `server/src/main/java/cn/cuckoox/wisediet/controller/dto/AuthTokenResponse.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/service/OAuthService.java`
- Modify: `server/src/test/java/cn/cuckoox/wisediet/AuthControllerIntegrationTest.java`

### Step 1: 在集成测试中加断言，验证登录响应含 `onboardingStep` 字段

在 `AuthControllerIntegrationTest.java` 的 `shouldReturnTokensForGoogleLogin` 测试中加一行断言：

```java
.jsonPath("$.onboardingStep").exists()
```

完整的 test body 变为：
```java
webTestClient.post().uri("/api/auth/google")
        .bodyValue(new OAuthLoginRequest("code-123", state))
        .exchange()
        .expectStatus().isOk()
        .expectBody()
        .jsonPath("$.accessToken").exists()
        .jsonPath("$.refreshToken").exists()
        .jsonPath("$.onboardingStep").exists();
```

### Step 2: 运行测试确认失败

```bash
cd server && ./mvnw test -pl . -Dtest=AuthControllerIntegrationTest#shouldReturnTokensForGoogleLogin -q 2>&1 | tail -20
```

期望：FAIL — `No value for JSON path "$.onboardingStep"`

### Step 3: 修改 `AuthTokenResponse.java` 加字段

```java
package cn.cuckoox.wisediet.controller.dto;

public record AuthTokenResponse(String accessToken, String refreshToken, int onboardingStep) {
}
```

### Step 4: 修改 `OAuthService.java` 传入 onboardingStep

找到文件末尾的 `.thenReturn(new AuthTokenResponse(...))` 这行（约第97行），修改为：

```java
.thenReturn(new AuthTokenResponse(accessToken, UUID.randomUUID().toString(), user.getOnboardingStep()))
```

注意：`user` 对象在外层 `flatMap(user -> ...)` 的 lambda 作用域中已可访问。完整的链式调用变为：

```java
.flatMap(user -> jwtService.createAccessToken(user.getId())
        .flatMap(accessToken -> sessionStore.saveSession(
                        jwtService.extractJti(accessToken),
                        user.getId(),
                        Duration.ofMinutes(15))
                .thenReturn(new AuthTokenResponse(accessToken, UUID.randomUUID().toString(), user.getOnboardingStep()))));
```

### Step 5: 运行测试确认通过

```bash
cd server && ./mvnw test -pl . -Dtest=AuthControllerIntegrationTest -q 2>&1 | tail -20
```

期望：BUILD SUCCESS，所有 `AuthControllerIntegrationTest` 测试通过。

### Step 6: 还需要新增一个测试，验证老用户（`onboardingStep=0`）登录返回正确值

在 `AuthControllerIntegrationTest.java` 中添加：

```java
@Autowired
private UserRepository userRepository;

@Test
void shouldReturnOnboardingStepZeroForExistingCompletedUser() {
    // Given: 已存在 onboardingStep=0 的老用户
    // AbstractIntegrationTest mock 的 oauth server 对 google 返回固定的 provider-id-1
    // 此处先插入该用户
    userRepository.save(new cn.cuckoox.wisediet.model.User(null, "completed@test.com", "google", "provider-id-1", 0)).block();

    String state = "completed-state-1";
    StepVerifier.create(sessionStore.saveOAuthState(state))
            .expectNext(true)
            .verifyComplete();

    webTestClient.post().uri("/api/auth/google")
            .bodyValue(new OAuthLoginRequest("code-123", state))
            .exchange()
            .expectStatus().isOk()
            .expectBody()
            .jsonPath("$.onboardingStep").isEqualTo(0);
}
```

（需要在类顶部 `@Autowired` 注入 `UserRepository`）

### Step 7: 运行所有 Auth 集成测试

```bash
cd server && ./mvnw test -pl . -Dtest=AuthControllerIntegrationTest -q 2>&1 | tail -30
```

期望：BUILD SUCCESS

### Step 8: Commit

```bash
cd server && git add src/main/java/cn/cuckoox/wisediet/controller/dto/AuthTokenResponse.java \
  src/main/java/cn/cuckoox/wisediet/service/OAuthService.java \
  src/test/java/cn/cuckoox/wisediet/AuthControllerIntegrationTest.java
git commit -m "feat: include onboardingStep in auth login response"
```

---

## Task 2：后端 — `UserRepository` 加 `completeOnboarding` 方法

**Files:**
- Modify: `server/src/main/java/cn/cuckoox/wisediet/repository/UserRepository.java`

### Step 1: 在 `UserRepository.java` 中新增方法

```java
package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.User;
import org.springframework.data.r2dbc.repository.Modifying;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Mono;

public interface UserRepository extends ReactiveCrudRepository<User, Long> {
    Mono<User> findByProviderAndProviderUserId(String provider, String providerUserId);

    @Modifying
    @Query("UPDATE users SET onboarding_step = 0 WHERE id = :userId")
    Mono<Void> completeOnboarding(Long userId);
}
```

### Step 2: Commit（此步骤无独立测试，将在 Task 3 集成验证）

```bash
cd server && git add src/main/java/cn/cuckoox/wisediet/repository/UserRepository.java
git commit -m "feat: add completeOnboarding query to UserRepository"
```

---

## Task 3：后端 — `OnboardingController.saveProfile` 改为 upsert + 完成 onboarding

**Files:**
- Modify: `server/src/main/java/cn/cuckoox/wisediet/controller/OnboardingController.java`
- Modify: `server/src/test/java/cn/cuckoox/wisediet/OnboardingApiIntegrationTest.java`

### Step 1: 编写失败测试 — 同一用户二次提交 profile 后只有一条记录

在 `OnboardingApiIntegrationTest.java` 中加入两个测试：

**测试1：同一用户二次提交，只有一条 profile 记录**

```java
@Test
void shouldUpsertProfileOnResubmit() {
    // Given: 构造第一次和第二次提交的 profile
    UserProfile first = new UserProfile(null, null, "Male", 30, 180.0, 70.0, "1", 2, null, null, null);
    UserProfile second = new UserProfile(null, null, "Female", 28, 165.0, 55.0, "2", 1, null, null, null);

    Mono<Boolean> flow = issueAuthenticatedToken(1)
            .flatMap(token -> Mono.fromCallable(() -> {
                // 第一次提交
                webTestClient.post().uri("/api/onboarding/profile")
                        .header("Authorization", "Bearer " + token)
                        .bodyValue(first)
                        .exchange()
                        .expectStatus().isOk();

                // 第二次提交
                webTestClient.post().uri("/api/onboarding/profile")
                        .header("Authorization", "Bearer " + token)
                        .bodyValue(second)
                        .exchange()
                        .expectStatus().isOk()
                        .expectBody(UserProfile.class)
                        .value(profile -> {
                            if (!"Female".equals(profile.getGender())) {
                                throw new AssertionError("expected updated gender Female, got: " + profile.getGender());
                            }
                        });
                return true;
            }).subscribeOn(Schedulers.boundedElastic()));

    StepVerifier.create(flow).expectNext(true).verifyComplete();

    // 验证数据库中该 userId 只有一条记录（取最新用户的 profile）
    StepVerifier.create(
            userRepository.findAll()
                    .filter(u -> "google".equals(u.getProvider()))
                    .last()
                    .flatMapMany(u -> userProfileRepository.findAll()
                            .filter(p -> u.getId().equals(p.getUserId())))
                    .count()
    ).expectNext(1L).verifyComplete();
}
```

**测试2：profile 提交成功后 `users.onboarding_step` 被置为 0**

```java
@Test
void shouldCompleteOnboardingAfterProfileSubmit() {
    UserProfile profile = new UserProfile(null, null, "Male", 25, 175.0, 68.0, null, 1, null, null, null);

    Mono<Boolean> flow = issueAuthenticatedToken(1)
            .flatMap(token -> {
                // 记录当前用户的 id（通过 token 解析，但这里用 findAll 找到最新插入的）
                return Mono.fromCallable(() -> {
                    webTestClient.post().uri("/api/onboarding/profile")
                            .header("Authorization", "Bearer " + token)
                            .bodyValue(profile)
                            .exchange()
                            .expectStatus().isOk();
                    return true;
                }).subscribeOn(Schedulers.boundedElastic());
            });

    StepVerifier.create(flow).expectNext(true).verifyComplete();

    // 验证最近插入的 onboarding_step=1 的用户，提交后变为 0
    StepVerifier.create(
            userRepository.findAll()
                    .filter(u -> "google".equals(u.getProvider()))
                    .last()
                    .map(u -> u.getOnboardingStep())
    ).expectNext(0).verifyComplete();
}
```

### Step 2: 运行测试确认失败

```bash
cd server && ./mvnw test -pl . -Dtest=OnboardingApiIntegrationTest#shouldUpsertProfileOnResubmit,OnboardingApiIntegrationTest#shouldCompleteOnboardingAfterProfileSubmit -q 2>&1 | tail -30
```

期望：测试失败（upsert 未实现，仍然插入多条；onboarding_step 未更新）

### Step 3: 修改 `OnboardingController.java`

需要新增 `UserRepository` 依赖，并修改 `saveProfile` 方法：

```java
package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.i18n.RequestLocaleResolver;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.repository.UserProfileRepository;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.security.CurrentUserService;
import org.springframework.context.MessageSource;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ServerWebExchange;
import jakarta.validation.Valid;
import reactor.core.publisher.Mono;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/onboarding")
public class OnboardingController {

    private final UserProfileRepository userProfileRepository;
    private final UserRepository userRepository;
    private final MessageSource messageSource;
    private final RequestLocaleResolver requestLocaleResolver;
    private final CurrentUserService currentUserService;

    public OnboardingController(UserProfileRepository userProfileRepository,
                                UserRepository userRepository,
                                MessageSource messageSource,
                                RequestLocaleResolver requestLocaleResolver,
                                CurrentUserService currentUserService) {
        this.userProfileRepository = userProfileRepository;
        this.userRepository = userRepository;
        this.messageSource = messageSource;
        this.requestLocaleResolver = requestLocaleResolver;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/profile")
    public Mono<UserProfile> saveProfile(@Valid @RequestBody UserProfile profile) {
        return currentUserService.currentUserId()
                .flatMap(userId -> userProfileRepository.findByUserId(userId)
                        .defaultIfEmpty(new UserProfile())
                        .flatMap(existing -> {
                            profile.setId(existing.getId()); // null → insert, non-null → update
                            profile.setUserId(userId);
                            return userProfileRepository.save(profile);
                        }))
                .flatMap(saved -> userRepository.completeOnboarding(saved.getUserId())
                        .thenReturn(saved));
    }

    // getStrategy 方法保持不变，直接复制原有代码
    @GetMapping("/strategy")
    public Mono<Map<String, Object>> getStrategy(ServerWebExchange exchange) {
        var locale = requestLocaleResolver.resolve(exchange);
        Map<String, Object> response = new HashMap<>();
        response.put("date", LocalDate.now().toString());
        response.put("title", messageSource.getMessage("onboarding.strategy.title", null, locale));
        response.put("summary", messageSource.getMessage("onboarding.strategy.summary", null, locale));

        Map<String, String> keyPoints = new LinkedHashMap<>();
        keyPoints.put(
                messageSource.getMessage("onboarding.strategy.key.energy", null, locale),
                messageSource.getMessage("onboarding.strategy.value.energy", null, locale)
        );
        keyPoints.put(
                messageSource.getMessage("onboarding.strategy.key.eyes", null, locale),
                messageSource.getMessage("onboarding.strategy.value.eyes", null, locale)
        );
        keyPoints.put(
                messageSource.getMessage("onboarding.strategy.key.stress", null, locale),
                messageSource.getMessage("onboarding.strategy.value.stress", null, locale)
        );

        response.put("key_points", keyPoints);
        Map<String, String> projectedImpact = new LinkedHashMap<>();
        projectedImpact.put("focus_boost", messageSource.getMessage("onboarding.strategy.impact.focusBoost", null, locale));
        projectedImpact.put("calorie_target", messageSource.getMessage("onboarding.strategy.impact.calorieTarget", null, locale));
        response.put("projected_impact", projectedImpact);

        Map<String, String> preferences = new LinkedHashMap<>();
        preferences.put("daily_focus", messageSource.getMessage("onboarding.strategy.preference.dailyFocus", null, locale));
        preferences.put("meal_frequency", messageSource.getMessage("onboarding.strategy.preference.mealFrequency", null, locale));
        preferences.put("cooking_level", messageSource.getMessage("onboarding.strategy.preference.cookingLevel", null, locale));
        preferences.put("budget", messageSource.getMessage("onboarding.strategy.preference.budget", null, locale));
        response.put("preferences", preferences);

        response.put("info_hint", messageSource.getMessage("onboarding.strategy.infoHint", null, locale));
        response.put("cta_text", messageSource.getMessage("onboarding.strategy.ctaText", null, locale));

        return Mono.just(response);
    }
}
```

### Step 4: 运行测试确认通过

```bash
cd server && ./mvnw test -pl . -Dtest=OnboardingApiIntegrationTest -q 2>&1 | tail -30
```

期望：BUILD SUCCESS，所有 `OnboardingApiIntegrationTest` 测试通过。

### Step 5: 运行所有后端测试（回归）

```bash
cd server && ./mvnw test -q 2>&1 | tail -30
```

期望：BUILD SUCCESS

### Step 6: Commit

```bash
cd server && git add src/main/java/cn/cuckoox/wisediet/controller/OnboardingController.java \
  src/test/java/cn/cuckoox/wisediet/OnboardingApiIntegrationTest.java
git commit -m "feat: upsert profile and complete onboarding on profile save"
```

---

## Task 4：后端 — 数据库 schema 加唯一约束

**Files:**
- Modify: `server/src/main/resources/schema.sql`

### Step 1: 修改 `schema.sql` 在 `user_profiles` 表中加唯一约束

将现有的：
```sql
CREATE TABLE IF NOT EXISTS "user_profiles" (
    id SERIAL PRIMARY KEY,
    user_id BIGINT,
    ...
);
```

修改 `user_id` 行为：
```sql
    user_id BIGINT UNIQUE,
```

完整的 `user_profiles` 表定义变为：
```sql
CREATE TABLE IF NOT EXISTS "user_profiles" (
    id SERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE,
    gender VARCHAR(50),
    age INT,
    height FLOAT,
    weight FLOAT,
    occupation_tag_ids TEXT,
    family_members INT,
    allergen_tag_ids TEXT,
    dietary_preference_tag_ids TEXT,
    custom_avoided_ingredients TEXT
);
```

### Step 2: 运行所有后端测试（回归）

```bash
cd server && ./mvnw test -q 2>&1 | tail -30
```

期望：BUILD SUCCESS（testcontainers 每次重建 DB，唯一约束生效）

### Step 3: Commit

```bash
cd server && git add src/main/resources/schema.sql
git commit -m "feat: add unique constraint on user_profiles.user_id"
```

---

## Task 5：前端 — 登录后从响应读取 `onboardingStep`

**Files:**
- Modify: `client/lib/features/auth/google_login.dart`
- Modify: `client/lib/features/auth/github_login.dart`

### Step 1: 修改 `google_login.dart`

找到文件末尾（约第88-94行）的 `return AuthState(...)` 块，将 `onboardingStep: 1` 改为从响应中读取：

```dart
final onboardingStep = (body['onboardingStep'] as num?)?.toInt() ?? 1;

return AuthState(
  isLoggedIn: true,
  onboardingStep: onboardingStep,
  accessToken: accessToken,
  refreshToken: refreshToken,
);
```

### Step 2: 修改 `github_login.dart`

同样找到末尾（约第77-82行）的 `return AuthState(...)` 块，修改：

```dart
final onboardingStep = (body['onboardingStep'] as num?)?.toInt() ?? 1;

return AuthState(
  isLoggedIn: true,
  onboardingStep: onboardingStep,
  accessToken: accessToken,
  refreshToken: refreshToken,
);
```

### Step 3: 运行现有前端测试确认没有破坏

```bash
cd client && flutter test test/features/auth/ --reporter=compact 2>&1 | tail -20
```

期望：All tests passed（若无 auth 测试则跳过此步）

### Step 4: Commit

```bash
cd client && git add lib/features/auth/google_login.dart lib/features/auth/github_login.dart
git commit -m "feat: read onboardingStep from login response instead of hardcoding 1"
```

---

## Task 6：前端 — `AuthController` 加 `completeOnboarding` 方法

**Files:**
- Modify: `client/lib/features/auth/auth_controller.dart`
- Modify: `client/test/features/auth/` (新增测试文件，如果目录存在)

### Step 1: 检查现有 auth 测试目录

```bash
ls client/test/features/auth/ 2>/dev/null || echo "no auth test dir"
```

### Step 2: 在 `auth_controller.dart` 中加 `completeOnboarding` 方法

在 `handleOnboardingRequired()` 方法（约第62行）之后加入：

```dart
void completeOnboarding() {
  state = AuthState(
    isLoggedIn: true,
    onboardingStep: 0,
    accessToken: state.accessToken,
    refreshToken: state.refreshToken,
  );
}
```

### Step 3: 若有 auth 测试文件，新增/追加测试

新建或追加到 `client/test/features/auth/auth_controller_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wise_diet/features/auth/auth_controller.dart';
import 'package:wise_diet/features/auth/auth_state.dart';

class _FakeAuthApi implements AuthApi {
  @override
  Future<AuthState> loginWithGoogle() async =>
      const AuthState(isLoggedIn: true, onboardingStep: 1, accessToken: 'tok', refreshToken: 'ref');

  @override
  Future<AuthState> loginWithGithub() async =>
      const AuthState(isLoggedIn: true, onboardingStep: 1, accessToken: 'tok', refreshToken: 'ref');
}

void main() {
  group('AuthController.completeOnboarding', () {
    test('sets onboardingStep to 0 and preserves tokens', () {
      final controller = AuthController(_FakeAuthApi());
      // 先模拟已登录状态
      controller.state = const AuthState(
        isLoggedIn: true,
        onboardingStep: 1,
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      );

      controller.completeOnboarding();

      expect(controller.state.onboardingStep, equals(0));
      expect(controller.state.isLoggedIn, isTrue);
      expect(controller.state.accessToken, equals('access-token'));
      expect(controller.state.refreshToken, equals('refresh-token'));
    });
  });
}
```

**注意：** 包名需与项目实际 `name` 字段一致，可查 `client/pubspec.yaml` 确认。

### Step 4: 运行测试

```bash
cd client && flutter test test/features/auth/ --reporter=compact 2>&1 | tail -20
```

期望：All tests passed

### Step 5: Commit

```bash
cd client && git add lib/features/auth/auth_controller.dart
# 如果有新增测试文件：
# git add test/features/auth/auth_controller_test.dart
git commit -m "feat: add completeOnboarding method to AuthController"
```

---

## Task 7：前端 — `LoadingAnalysisScreen` 提交成功后调用 `completeOnboarding`

**Files:**
- Modify: `client/lib/features/onboarding/screens/loading_analysis_screen.dart`

### Step 1: 在 `_processData()` 方法中，profile 提交成功后调用 `completeOnboarding`

找到 `loading_analysis_screen.dart` 中 `_processData()` 方法（约第91行），在 `await _service.submitProfile(profile);` 之后加一行：

```dart
Future<void> _processData() async {
  try {
    final profile = ref.read(onboardingProvider);

    await _service.submitProfile(profile);
    // 通知 AuthController onboarding 已完成
    ref.read(authControllerProvider.notifier).completeOnboarding();

    await Future.delayed(const Duration(seconds: 2));
    final strategy = await _service.getStrategy();

    if (!mounted) {
      return;
    }

    if (_progressController.value < 1.0) {
      _progressController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 550),
      );
    }

    context.go('/onboarding/strategy', extra: strategy);
  } catch (e) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.errorPrefix(e.toString()))));
    context.go('/onboarding/family');
  }
}
```

### Step 2: 确认需要正确导入 `authControllerProvider`

在 `loading_analysis_screen.dart` 文件顶部导入区，加入：

```dart
import '../../../features/auth/auth_controller.dart';
```

（若文件中已有相对路径的 auth 导入，检查路径是否正确）

### Step 3: 运行相关 widget 测试

```bash
cd client && flutter test test/features/onboarding/ --reporter=compact 2>&1 | tail -20
```

期望：All tests passed（如果有 loading screen 的测试）

### Step 4: 运行所有前端测试（回归）

```bash
cd client && flutter test --reporter=compact 2>&1 | tail -20
```

期望：All tests passed

### Step 5: Commit

```bash
cd client && git add lib/features/onboarding/screens/loading_analysis_screen.dart
git commit -m "feat: call completeOnboarding after profile submit in onboarding flow"
```

---

## Task 8：最终回归测试

### Step 1: 运行所有后端测试

```bash
cd server && ./mvnw test -q 2>&1 | tail -30
```

期望：BUILD SUCCESS

### Step 2: 运行所有前端测试

```bash
cd client && flutter test --reporter=compact 2>&1 | tail -20
```

期望：All tests passed

### Step 3: 验证核心场景

**场景1：老用户（onboardingStep=0）重新登录不再引导**
- 后端返回 `onboardingStep: 0` → 前端 router 条件 `onboardingStep > 0` 为 false → 不跳转 onboarding

**场景2：新用户（onboardingStep=1）登录后正常引导**
- 后端返回 `onboardingStep: 1` → 前端 router 跳转 `/onboarding/basic-info`

**场景3：用户二次经过 onboarding 不重复创建 profile**
- `saveProfile` upsert → 只有一条记录，内容被更新

**场景4：冷启动时若 onboarding 未完成**
- 本地 `onboardingStep` 默认为 0，首次 API 请求触发 `OnboardingGateFilter` 403 → `handleOnboardingRequired()` → 跳转 onboarding
