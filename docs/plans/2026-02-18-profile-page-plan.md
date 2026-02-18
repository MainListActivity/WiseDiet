# Profile Page Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement a full-featured Profile page where users can view and inline-edit all their personal data (basic info, occupation tags, dietary preferences, household size), backed by `GET /api/profile` and `PATCH /api/profile` server endpoints.

**Architecture:** Add a `user_id` FK to `user_profiles` table to link profiles to users. New `ProfileController` + `ProfileService` on the server follows the same `CurrentUserService` pattern as `TodayController`. On the client, a new `ProfileService` + `profileProvider` (Riverpod `AsyncNotifier`) drives the `ProfileScreen` which renders four editable Card sections with inline editing.

**Tech Stack:** Spring Boot 4 / WebFlux / R2DBC (server) · Flutter / Riverpod / GoRouter (client) · JUnit 5 / Reactor Test / Testcontainers (server tests) · flutter_test / Mockito (client tests)

---

## Prerequisites

> Key files to understand before starting:
> - Design doc: `docs/plans/2026-02-18-profile-page-design.md`
> - Server pattern: `server/src/main/java/cn/cuckoox/wisediet/controller/TodayController.java`
> - Server test pattern: `server/src/test/java/cn/cuckoox/wisediet/OnboardingIntegrationTest.java`
> - Server test base: `server/src/test/java/cn/cuckoox/wisediet/AbstractIntegrationTest.java`
> - Client pattern (provider): `client/lib/features/onboarding/providers/tag_provider.dart`
> - Client pattern (screen): `client/lib/features/history/screens/profile_screen.dart`

---

## Task 1: Design Mockup HTML

Create the HTML design spec for `design/13_profile/`.

**Files:**
- Create: `design/13_profile/code.html`

**Step 1: Create the design directory and HTML file**

```bash
mkdir -p /Users/y/IdeaProjects/WiseDiet/design/13_profile
```

Create `design/13_profile/code.html` with the following content — a full-screen mobile mockup matching the WiseDiet color theme (`#4b7c5a` primary). It must show: AppBar with back arrow + "个人信息" title, four Card sections (基本信息/居家参数/职业标签/饮食偏好与过敏), one field in inline-edit state (体重 with a text input), and the logout button at the bottom. Include a dark-mode toggle button. Use Tailwind CSS + Material Symbols (same setup as `design/03b_onboarding_profile/code.html`).

```html
<!DOCTYPE html>
<html class="light" lang="zh"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>WiseDiet - Profile</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">
tailwind.config = {
    darkMode: "class",
    theme: {
        extend: {
            colors: {
                "primary": "#4b7c5a",
                "secondary": "#2C3E50",
                "background-light": "#f6f7f7",
                "background-dark": "#161c18",
                "surface-light": "#ffffff",
                "surface-dark": "#1e2420",
            },
            fontFamily: { "display": ["Inter", "sans-serif"] },
        },
    },
}
</script>
<style>
body { min-height: max(884px, 100dvh); }
.material-symbols-outlined { font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24; }
</style>
</head>
<body class="bg-background-light dark:bg-background-dark font-display transition-colors duration-300">

<!-- Dark mode toggle -->
<div class="fixed top-4 right-4 z-50">
  <button onclick="document.documentElement.classList.toggle('dark')"
          class="w-9 h-9 rounded-full bg-white dark:bg-surface-dark shadow flex items-center justify-center border border-gray-200 dark:border-gray-700">
    <span class="material-symbols-outlined text-gray-600 dark:text-gray-300 text-[18px]">dark_mode</span>
  </button>
</div>

<!-- Phone frame -->
<div class="flex justify-center py-8 px-4">
<div class="w-full max-w-sm bg-background-light dark:bg-background-dark min-h-screen rounded-3xl shadow-2xl overflow-hidden border border-gray-200 dark:border-gray-800">

  <!-- AppBar -->
  <div class="flex items-center px-2 pt-3 pb-2 bg-surface-light dark:bg-surface-dark border-b border-gray-100 dark:border-gray-800">
    <button class="p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800">
      <span class="material-symbols-outlined text-secondary dark:text-gray-300">arrow_back</span>
    </button>
    <h1 class="flex-1 text-center text-base font-semibold text-secondary dark:text-white">个人信息</h1>
    <div class="w-10"></div>
  </div>

  <!-- Scrollable content -->
  <div class="overflow-y-auto px-4 py-4 space-y-4">

    <!-- Card: 基本信息 -->
    <div class="bg-surface-light dark:bg-surface-dark rounded-2xl border border-gray-100 dark:border-gray-700 overflow-hidden">
      <div class="px-4 pt-4 pb-2">
        <p class="text-xs font-semibold text-primary uppercase tracking-wider">基本信息</p>
      </div>
      <!-- 性别 -->
      <div class="px-4 py-3 flex items-center justify-between border-b border-gray-50 dark:border-gray-700/50">
        <span class="text-sm text-gray-500 dark:text-gray-400 w-20">性别</span>
        <span class="flex-1 text-sm font-medium text-secondary dark:text-white text-right">男</span>
        <button class="ml-3 p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700">
          <span class="material-symbols-outlined text-gray-400 text-[18px]">edit</span>
        </button>
      </div>
      <!-- 年龄 -->
      <div class="px-4 py-3 flex items-center justify-between border-b border-gray-50 dark:border-gray-700/50">
        <span class="text-sm text-gray-500 dark:text-gray-400 w-20">年龄</span>
        <span class="flex-1 text-sm font-medium text-secondary dark:text-white text-right">28 岁</span>
        <button class="ml-3 p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700">
          <span class="material-symbols-outlined text-gray-400 text-[18px]">edit</span>
        </button>
      </div>
      <!-- 身高 -->
      <div class="px-4 py-3 flex items-center justify-between border-b border-gray-50 dark:border-gray-700/50">
        <span class="text-sm text-gray-500 dark:text-gray-400 w-20">身高</span>
        <span class="flex-1 text-sm font-medium text-secondary dark:text-white text-right">175 cm</span>
        <button class="ml-3 p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700">
          <span class="material-symbols-outlined text-gray-400 text-[18px]">edit</span>
        </button>
      </div>
      <!-- 体重 — INLINE EDIT STATE -->
      <div class="px-4 py-2 bg-primary/5 dark:bg-primary/10">
        <div class="flex items-center gap-2">
          <span class="text-sm text-gray-500 dark:text-gray-400 w-20 flex-shrink-0">体重</span>
          <div class="flex-1 flex items-center gap-1">
            <input type="number" value="70" class="flex-1 text-sm bg-white dark:bg-gray-800 border border-primary rounded-lg px-3 py-1.5 text-secondary dark:text-white focus:outline-none focus:ring-2 focus:ring-primary/50" />
            <span class="text-xs text-gray-400 flex-shrink-0">kg</span>
          </div>
          <button class="p-1.5 rounded-full bg-primary text-white ml-1">
            <span class="material-symbols-outlined text-[18px]">check</span>
          </button>
          <button class="p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700">
            <span class="material-symbols-outlined text-gray-400 text-[18px]">close</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Card: 居家参数 -->
    <div class="bg-surface-light dark:bg-surface-dark rounded-2xl border border-gray-100 dark:border-gray-700 overflow-hidden">
      <div class="px-4 pt-4 pb-2">
        <p class="text-xs font-semibold text-primary uppercase tracking-wider">居家参数</p>
      </div>
      <div class="px-4 py-3 flex items-center justify-between">
        <span class="text-sm text-gray-500 dark:text-gray-400 w-28">家庭用餐人数</span>
        <span class="flex-1 text-sm font-medium text-secondary dark:text-white text-right">3 人</span>
        <button class="ml-3 p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700">
          <span class="material-symbols-outlined text-gray-400 text-[18px]">edit</span>
        </button>
      </div>
    </div>

    <!-- Card: 职业标签 -->
    <div class="bg-surface-light dark:bg-surface-dark rounded-2xl border border-gray-100 dark:border-gray-700 overflow-hidden">
      <div class="px-4 pt-4 pb-2 flex items-center justify-between">
        <p class="text-xs font-semibold text-primary uppercase tracking-wider">职业标签</p>
        <button class="text-xs text-primary font-medium flex items-center gap-1">
          <span class="material-symbols-outlined text-[14px]">edit</span>编辑
        </button>
      </div>
      <div class="px-4 pb-4 flex flex-wrap gap-2">
        <span class="inline-flex items-center gap-1 px-3 py-1 bg-primary/10 dark:bg-primary/20 text-primary rounded-full text-xs font-medium">
          <span>💻</span> 程序员
        </span>
        <span class="inline-flex items-center gap-1 px-3 py-1 bg-primary/10 dark:bg-primary/20 text-primary rounded-full text-xs font-medium">
          <span>🧠</span> 高压工作
        </span>
      </div>
    </div>

    <!-- Card: 饮食偏好与过敏 -->
    <div class="bg-surface-light dark:bg-surface-dark rounded-2xl border border-gray-100 dark:border-gray-700 overflow-hidden">
      <div class="px-4 pt-4 pb-2">
        <p class="text-xs font-semibold text-primary uppercase tracking-wider">饮食偏好与过敏</p>
      </div>
      <!-- 过敏原 -->
      <div class="px-4 pb-3 border-b border-gray-50 dark:border-gray-700/50">
        <div class="flex items-center justify-between mb-2">
          <span class="text-sm text-gray-500 dark:text-gray-400">过敏原</span>
          <button class="text-xs text-primary font-medium flex items-center gap-1">
            <span class="material-symbols-outlined text-[14px]">edit</span>编辑
          </button>
        </div>
        <div class="flex flex-wrap gap-1.5">
          <span class="inline-flex items-center gap-1 px-2.5 py-1 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-full text-xs font-medium border border-red-100 dark:border-red-800">🥜 花生</span>
          <span class="inline-flex items-center gap-1 px-2.5 py-1 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-full text-xs font-medium border border-red-100 dark:border-red-800">🥛 牛奶</span>
        </div>
      </div>
      <!-- 饮食偏好 -->
      <div class="px-4 py-3 border-b border-gray-50 dark:border-gray-700/50">
        <div class="flex items-center justify-between mb-2">
          <span class="text-sm text-gray-500 dark:text-gray-400">饮食偏好</span>
          <button class="text-xs text-primary font-medium flex items-center gap-1">
            <span class="material-symbols-outlined text-[14px]">edit</span>编辑
          </button>
        </div>
        <div class="flex flex-wrap gap-1.5">
          <span class="inline-flex items-center gap-1 px-2.5 py-1 bg-primary/10 dark:bg-primary/20 text-primary rounded-full text-xs font-medium">🌾 低GI</span>
          <span class="inline-flex items-center gap-1 px-2.5 py-1 bg-primary/10 dark:bg-primary/20 text-primary rounded-full text-xs font-medium">💪 高蛋白</span>
        </div>
      </div>
      <!-- 自定义忌口 -->
      <div class="px-4 py-3 flex items-center justify-between">
        <span class="text-sm text-gray-500 dark:text-gray-400 w-20">自定义忌口</span>
        <span class="flex-1 text-sm font-medium text-secondary dark:text-white text-right">香菜、榴莲</span>
        <button class="ml-3 p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700">
          <span class="material-symbols-outlined text-gray-400 text-[18px]">edit</span>
        </button>
      </div>
    </div>

    <!-- Divider -->
    <div class="border-t border-gray-200 dark:border-gray-700 my-2"></div>

    <!-- Logout button -->
    <button class="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-2xl border border-red-200 dark:border-red-800 text-red-500 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors font-medium text-sm">
      <span class="material-symbols-outlined text-[20px]">logout</span>
      退出登录
    </button>

    <div class="h-8"></div>
  </div>
</div>
</div>

</body>
</html>
```

**Step 2: Verify the file was created**

```bash
ls -la /Users/y/IdeaProjects/WiseDiet/design/13_profile/
```

Expected: `code.html` present.

**Step 3: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add design/13_profile/
git commit -m "design: add profile page mockup (13_profile)"
```

---

## Task 2: Add `user_id` to `user_profiles` Schema

The `user_profiles` table currently has no FK to `users`. We need to add `user_id` to link profiles to users so we can look up a profile by the authenticated user.

**Files:**
- Modify: `server/src/main/resources/schema.sql`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/model/UserProfile.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/repository/UserProfileRepository.java`

**Step 1: Add `user_id` column to schema.sql**

In `server/src/main/resources/schema.sql`, find the `user_profiles` CREATE TABLE statement and add `user_id BIGINT` after the `id` line:

```sql
CREATE TABLE IF NOT EXISTS "user_profiles" (
    id SERIAL PRIMARY KEY,
    user_id BIGINT,              -- 关联的用户ID
    gender VARCHAR(50),
    ...
```

**Step 2: Add `userId` field to `UserProfile.java`**

In `server/src/main/java/cn/cuckoox/wisediet/model/UserProfile.java`, add the field after `private Long id;`:

```java
private Long userId;
```

The full updated class header section:
```java
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("user_profiles")
public class UserProfile {
    @Id
    private Long id;
    private Long userId;
    @NotBlank
    @Pattern(regexp = "(?i)male|female|other")
    private String gender;
    // ... rest unchanged
```

**Step 3: Add `findByUserId` to repository**

In `server/src/main/java/cn/cuckoox/wisediet/repository/UserProfileRepository.java`:

```java
package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.UserProfile;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

@Repository
public interface UserProfileRepository extends R2dbcRepository<UserProfile, Long> {
    Mono<UserProfile> findByUserId(Long userId);
}
```

**Step 4: Verify existing tests still pass**

```bash
cd /Users/y/IdeaProjects/WiseDiet/server
./mvnw test -pl . --timeout 120
```

Expected: All existing tests pass (the new nullable column doesn't break existing tests).

**Step 5: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add server/src/main/resources/schema.sql \
        server/src/main/java/cn/cuckoox/wisediet/model/UserProfile.java \
        server/src/main/java/cn/cuckoox/wisediet/repository/UserProfileRepository.java
git commit -m "feat: add user_id FK to user_profiles table and repository query"
```

---

## Task 3: Server — Integration Tests for `GET /api/profile` and `PATCH /api/profile`

Write failing integration tests before implementing the endpoints.

**Files:**
- Create: `server/src/test/java/cn/cuckoox/wisediet/ProfileApiIntegrationTest.java`

**Step 1: Write the integration test class**

```java
package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.repository.UserProfileRepository;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.test.StepVerifier;

import java.time.Duration;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class ProfileApiIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private UserProfileRepository userProfileRepository;
    @Autowired
    private JwtService jwtService;
    @Autowired
    private SessionStore sessionStore;

    @Test
    void getProfile_withoutToken_returns401() {
        webTestClient.get().uri("/api/profile")
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void getProfile_whenProfileExists_returns200WithData() {
        Mono<Boolean> flow = createUserWithProfile("get-profile@test.com")
                .flatMap(pair -> Mono.fromCallable(() -> {
                    webTestClient.get().uri("/api/profile")
                            .header("Authorization", "Bearer " + pair.token())
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody()
                            .jsonPath("$.gender").isEqualTo("Male")
                            .jsonPath("$.age").isEqualTo(30)
                            .jsonPath("$.height").isEqualTo(175.0)
                            .jsonPath("$.weight").isEqualTo(75.0)
                            .jsonPath("$.familyMembers").isEqualTo(2);
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow).expectNext(true).verifyComplete();
    }

    @Test
    void getProfile_whenNoProfile_returns404() {
        Mono<Boolean> flow = createUserToken("no-profile@test.com")
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.get().uri("/api/profile")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isNotFound();
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow).expectNext(true).verifyComplete();
    }

    @Test
    void patchProfile_withoutToken_returns401() {
        webTestClient.patch().uri("/api/profile")
                .bodyValue(Map.of("weight", 80.0))
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void patchProfile_updatesWeightOnly() {
        Mono<Boolean> flow = createUserWithProfile("patch-weight@test.com")
                .flatMap(pair -> Mono.fromCallable(() -> {
                    webTestClient.patch().uri("/api/profile")
                            .header("Authorization", "Bearer " + pair.token())
                            .header("Content-Type", "application/json")
                            .bodyValue(Map.of("weight", 80.5))
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody()
                            .jsonPath("$.weight").isEqualTo(80.5)
                            .jsonPath("$.age").isEqualTo(30);   // unchanged
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow).expectNext(true).verifyComplete();
    }

    @Test
    void patchProfile_updatesOccupationTags() {
        Mono<Boolean> flow = createUserWithProfile("patch-tags@test.com")
                .flatMap(pair -> Mono.fromCallable(() -> {
                    webTestClient.patch().uri("/api/profile")
                            .header("Authorization", "Bearer " + pair.token())
                            .header("Content-Type", "application/json")
                            .bodyValue(Map.of("occupationTagIds", "3,4,5"))
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody()
                            .jsonPath("$.occupationTagIds").isEqualTo("3,4,5");
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow).expectNext(true).verifyComplete();
    }

    // Helper record
    record UserTokenPair(Long userId, String token) {}

    private Mono<String> createUserToken(String email) {
        return userRepository.save(new User(null, email, "google",
                        "profile-test-provider-" + System.nanoTime(), 0))
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(token -> sessionStore.saveSession(
                                jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }

    private Mono<UserTokenPair> createUserWithProfile(String email) {
        return userRepository.save(new User(null, email, "google",
                        "profile-test-provider-" + System.nanoTime(), 0))
                .flatMap(user -> {
                    UserProfile profile = new UserProfile();
                    profile.setUserId(user.getId());
                    profile.setGender("Male");
                    profile.setAge(30);
                    profile.setHeight(175.0);
                    profile.setWeight(75.0);
                    profile.setFamilyMembers(2);
                    profile.setOccupationTagIds("1,2");
                    return userProfileRepository.save(profile)
                            .then(jwtService.createAccessToken(user.getId()))
                            .flatMap(token -> sessionStore.saveSession(
                                    jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                                    .thenReturn(new UserTokenPair(user.getId(), token)));
                });
    }
}
```

**Step 2: Run tests — expect them to FAIL (endpoints don't exist yet)**

```bash
cd /Users/y/IdeaProjects/WiseDiet/server
./mvnw test -Dtest=ProfileApiIntegrationTest --timeout 120
```

Expected: FAIL — `404 Not Found` on `/api/profile` or similar compilation error if classes don't exist.

**Step 3: Commit the failing tests**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add server/src/test/java/cn/cuckoox/wisediet/ProfileApiIntegrationTest.java
git commit -m "test: add failing integration tests for GET/PATCH /api/profile"
```

---

## Task 4: Server — `ProfileUpdateRequest` DTO

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/dto/ProfileUpdateRequest.java`

**Step 1: Create the DTO**

```java
package cn.cuckoox.wisediet.controller.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProfileUpdateRequest(
        String gender,
        Integer age,
        Double height,
        Double weight,
        Integer familyMembers,
        String occupationTagIds,
        String allergenTagIds,
        String dietaryPreferenceTagIds,
        String customAvoidedIngredients
) {}
```

**Step 2: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add server/src/main/java/cn/cuckoox/wisediet/controller/dto/ProfileUpdateRequest.java
git commit -m "feat: add ProfileUpdateRequest DTO"
```

---

## Task 5: Server — `ProfileService`

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/service/ProfileService.java`

**Step 1: Create the service**

```java
package cn.cuckoox.wisediet.service;

import cn.cuckoox.wisediet.controller.dto.ProfileUpdateRequest;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.repository.UserProfileRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

@Service
public class ProfileService {

    private final UserProfileRepository userProfileRepository;

    public ProfileService(UserProfileRepository userProfileRepository) {
        this.userProfileRepository = userProfileRepository;
    }

    public Mono<UserProfile> getProfile(Long userId) {
        return userProfileRepository.findByUserId(userId)
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND, "Profile not found")));
    }

    public Mono<UserProfile> patchProfile(Long userId, ProfileUpdateRequest req) {
        return userProfileRepository.findByUserId(userId)
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND, "Profile not found")))
                .flatMap(profile -> {
                    if (req.gender() != null) profile.setGender(req.gender());
                    if (req.age() != null) profile.setAge(req.age());
                    if (req.height() != null) profile.setHeight(req.height());
                    if (req.weight() != null) profile.setWeight(req.weight());
                    if (req.familyMembers() != null) profile.setFamilyMembers(req.familyMembers());
                    if (req.occupationTagIds() != null) profile.setOccupationTagIds(req.occupationTagIds());
                    if (req.allergenTagIds() != null) profile.setAllergenTagIds(req.allergenTagIds());
                    if (req.dietaryPreferenceTagIds() != null) profile.setDietaryPreferenceTagIds(req.dietaryPreferenceTagIds());
                    if (req.customAvoidedIngredients() != null) profile.setCustomAvoidedIngredients(req.customAvoidedIngredients());
                    return userProfileRepository.save(profile);
                });
    }
}
```

**Step 2: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add server/src/main/java/cn/cuckoox/wisediet/service/ProfileService.java
git commit -m "feat: add ProfileService with get and patch operations"
```

---

## Task 6: Server — `ProfileController`

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/ProfileController.java`

**Step 1: Create the controller**

```java
package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.controller.dto.ProfileUpdateRequest;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.security.CurrentUserService;
import cn.cuckoox.wisediet.service.ProfileService;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/profile")
public class ProfileController {

    private final ProfileService profileService;
    private final CurrentUserService currentUserService;

    public ProfileController(ProfileService profileService, CurrentUserService currentUserService) {
        this.profileService = profileService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public Mono<UserProfile> getProfile() {
        return currentUserService.currentUserId()
                .flatMap(profileService::getProfile);
    }

    @PatchMapping
    public Mono<UserProfile> patchProfile(@RequestBody ProfileUpdateRequest request) {
        return currentUserService.currentUserId()
                .flatMap(userId -> profileService.patchProfile(userId, request));
    }
}
```

**Step 2: Run the integration tests — they should now pass**

```bash
cd /Users/y/IdeaProjects/WiseDiet/server
./mvnw test -Dtest=ProfileApiIntegrationTest --timeout 120
```

Expected: All 6 tests PASS.

**Step 3: Run all server tests to confirm no regressions**

```bash
cd /Users/y/IdeaProjects/WiseDiet/server
./mvnw test --timeout 120
```

Expected: All tests pass.

**Step 4: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add server/src/main/java/cn/cuckoox/wisediet/controller/ProfileController.java
git commit -m "feat: add ProfileController with GET and PATCH /api/profile endpoints"
```

---

## Task 7: Server — Update `OnboardingController` to Set `userId` on Profile Save

When onboarding saves a profile, it must now also set `userId`. Otherwise newly onboarded users' profiles won't be retrievable.

**Files:**
- Modify: `server/src/main/java/cn/cuckoox/wisediet/controller/OnboardingController.java`
- Modify: `server/src/test/java/cn/cuckoox/wisediet/OnboardingIntegrationTest.java` (update assertion)

**Step 1: Inject `CurrentUserService` into `OnboardingController`**

Modify `OnboardingController.java` — inject `CurrentUserService` and update the `saveProfile` method:

```java
// Add to imports:
import cn.cuckoox.wisediet.security.CurrentUserService;

// Add to constructor parameters and fields:
private final CurrentUserService currentUserService;

// Update saveProfile method:
@PostMapping("/profile")
public Mono<UserProfile> saveProfile(@Valid @RequestBody UserProfile profile) {
    return currentUserService.currentUserId()
            .flatMap(userId -> {
                profile.setUserId(userId);
                return userProfileRepository.save(profile);
            });
}
```

**Step 2: Update the onboarding test assertion to verify userId is set**

In `OnboardingIntegrationTest.java`, update `shouldCreateUserProfile` to also assert:
```java
assertNotNull(saved.getUserId());
```

**Step 3: Run onboarding tests**

```bash
cd /Users/y/IdeaProjects/WiseDiet/server
./mvnw test -Dtest=OnboardingIntegrationTest --timeout 120
```

Expected: PASS.

**Step 4: Run all tests**

```bash
cd /Users/y/IdeaProjects/WiseDiet/server
./mvnw test --timeout 120
```

Expected: All pass.

**Step 5: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add server/src/main/java/cn/cuckoox/wisediet/controller/OnboardingController.java \
        server/src/test/java/cn/cuckoox/wisediet/OnboardingIntegrationTest.java
git commit -m "fix: set userId on UserProfile when saving during onboarding"
```

---

## Task 8: Client — Add i18n Keys for Profile Page

Add all new strings needed for the profile page UI.

**Files:**
- Modify: `client/lib/l10n/app_en.arb`
- Modify: `client/lib/l10n/app_zh.arb`

**Step 1: Add keys to `app_en.arb`**

After the existing `"profileLogoutConfirmAction"` line, add:

```json
  "profileSectionBasicInfo": "Basic Info",
  "profileSectionHousehold": "Household",
  "profileSectionOccupation": "Occupation Tags",
  "profileSectionDiet": "Diet & Allergies",
  "profileFieldGender": "Gender",
  "profileFieldAge": "Age",
  "profileFieldHeight": "Height",
  "profileFieldWeight": "Weight",
  "profileFieldFamilyMembers": "Household Diners",
  "profileFieldOccupationTags": "Occupation Tags",
  "profileFieldAllergens": "Allergens",
  "profileFieldDietaryPreferences": "Dietary Preferences",
  "profileFieldCustomAvoid": "Custom Avoid",
  "profileEditButton": "Edit",
  "profileSaveError": "Failed to save. Please try again.",
  "profileNoTags": "None selected",
  "profileNoCustomAvoid": "None"
```

**Step 2: Add keys to `app_zh.arb`**

After `"profileLogoutConfirmAction"`, add:

```json
  "profileSectionBasicInfo": "基本信息",
  "profileSectionHousehold": "居家参数",
  "profileSectionOccupation": "职业标签",
  "profileSectionDiet": "饮食偏好与过敏",
  "profileFieldGender": "性别",
  "profileFieldAge": "年龄",
  "profileFieldHeight": "身高",
  "profileFieldWeight": "体重",
  "profileFieldFamilyMembers": "家庭用餐人数",
  "profileFieldOccupationTags": "职业标签",
  "profileFieldAllergens": "过敏原",
  "profileFieldDietaryPreferences": "饮食偏好",
  "profileFieldCustomAvoid": "自定义忌口",
  "profileEditButton": "编辑",
  "profileSaveError": "保存失败，请重试",
  "profileNoTags": "未选择",
  "profileNoCustomAvoid": "无"
```

**Step 3: Regenerate l10n**

```bash
cd /Users/y/IdeaProjects/WiseDiet/client
flutter gen-l10n
```

Expected: No errors; `app_localizations_en.dart` and `app_localizations_zh.dart` regenerated with new keys.

**Step 4: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add client/lib/l10n/
git commit -m "feat: add i18n keys for profile page sections and fields"
```

---

## Task 9: Client — `ProfileService` (API Layer)

**Files:**
- Create: `client/lib/features/history/services/profile_service.dart`

**Step 1: Create the service**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../onboarding/models/user_profile.dart';

class ProfileService {
  ProfileService({http.Client? client}) : _client = client ?? ApiClient();

  final http.Client _client;

  Future<UserProfile> getProfile() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/profile'),
    );
    if (response.statusCode == 200) {
      return UserProfile.fromJson(
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('Failed to load profile (${response.statusCode})');
  }

  Future<UserProfile> patchProfile(Map<String, dynamic> fields) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/profile'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(fields),
    );
    if (response.statusCode == 200) {
      return UserProfile.fromJson(
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('Failed to update profile (${response.statusCode})');
  }
}
```

**Step 2: Add `fromJson` factory to `UserProfile` model**

In `client/lib/features/onboarding/models/user_profile.dart`, add the `fromJson` factory:

```dart
factory UserProfile.fromJson(Map<String, dynamic> json) {
  return UserProfile(
    gender: json['gender'] as String?,
    age: json['age'] as int?,
    height: (json['height'] as num?)?.toDouble(),
    weight: (json['weight'] as num?)?.toDouble(),
    occupationTags: _parseIds(json['occupationTagIds']),
    familyMembers: json['familyMembers'] as int? ?? 1,
    allergenTagIds: _parseIds(json['allergenTagIds']),
    dietaryPreferenceTagIds: _parseIds(json['dietaryPreferenceTagIds']),
    customAvoidedIngredients: _parseList(json['customAvoidedIngredients']),
  );
}

static Set<int> _parseIds(dynamic value) {
  if (value == null || value.toString().isEmpty) return {};
  return value.toString().split(',')
      .where((s) => s.trim().isNotEmpty)
      .map((s) => int.parse(s.trim()))
      .toSet();
}

static List<String> _parseList(dynamic value) {
  if (value == null || value.toString().isEmpty) return [];
  return value.toString().split(',')
      .where((s) => s.trim().isNotEmpty)
      .map((s) => s.trim())
      .toList();
}
```

**Step 3: Run unit tests to ensure no breakage**

```bash
cd /Users/y/IdeaProjects/WiseDiet/client
flutter test
```

Expected: All existing tests pass.

**Step 4: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add client/lib/features/history/services/profile_service.dart \
        client/lib/features/onboarding/models/user_profile.dart
git commit -m "feat: add ProfileService and UserProfile.fromJson factory"
```

---

## Task 10: Client — `profileProvider` (Riverpod State)

**Files:**
- Create: `client/lib/features/history/providers/profile_provider.dart`

**Step 1: Create the provider file**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client_provider.dart';
import '../../onboarding/models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  late ProfileService _service;

  @override
  Future<UserProfile> build() async {
    final client = ref.watch(apiClientProvider);
    _service = ProfileService(client: client);
    return _service.getProfile();
  }

  Future<void> updateField(Map<String, dynamic> fields) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.patchProfile(fields));
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);
```

**Step 2: Write a widget test to verify provider behavior with a mock (we'll test via the screen in Task 11)**

No standalone provider unit test needed — the screen tests will cover the interactions.

**Step 3: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add client/lib/features/history/providers/profile_provider.dart
git commit -m "feat: add profileProvider AsyncNotifier for profile state management"
```

---

## Task 11: Client — Widget Tests for `ProfileScreen`

Write failing widget tests before implementing the screen.

**Files:**
- Create: `client/test/features/history/profile_screen_test.dart`

**Step 1: Write the widget tests**

The tests use a mock `ProfileService` via provider override. They test:
1. Loading state shows `CircularProgressIndicator`
2. Loaded state shows four card section headers
3. Tapping a numeric field's edit icon shows an inline `TextField`
4. Tags section shows an "Edit" button
5. Logout button is still present

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/history/providers/profile_provider.dart';
import 'package:wise_diet/features/history/screens/profile_screen.dart';
import 'package:wise_diet/features/onboarding/models/user_profile.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

// Helper to build the widget under test with a provider override
Widget buildProfileScreen(AsyncValue<UserProfile> profileValue) {
  return ProviderScope(
    overrides: [
      profileProvider.overrideWith(() => _FakeProfileNotifier(profileValue)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProfileScreen(),
    ),
  );
}

class _FakeProfileNotifier extends AsyncNotifier<UserProfile> {
  _FakeProfileNotifier(this._value);
  final AsyncValue<UserProfile> _value;

  @override
  Future<UserProfile> build() async {
    if (_value is AsyncData<UserProfile>) return _value.value;
    if (_value is AsyncError) throw (_value as AsyncError).error;
    await Future.delayed(const Duration(seconds: 60)); // never resolves for loading test
    throw UnimplementedError();
  }
}

final _testProfile = UserProfile(
  gender: 'Male',
  age: 28,
  height: 175.0,
  weight: 70.0,
  occupationTags: {1, 2},
  familyMembers: 3,
  allergenTagIds: {3},
  dietaryPreferenceTagIds: {4},
  customAvoidedIngredients: ['香菜'],
);

void main() {
  testWidgets('shows loading indicator while profile is loading', (tester) async {
    await tester.pumpWidget(
      buildProfileScreen(const AsyncValue.loading()),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows four section cards when profile is loaded', (tester) async {
    await tester.pumpWidget(
      buildProfileScreen(AsyncValue.data(_testProfile)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-section-basic-info')), findsOneWidget);
    expect(find.byKey(const Key('profile-section-household')), findsOneWidget);
    expect(find.byKey(const Key('profile-section-occupation')), findsOneWidget);
    expect(find.byKey(const Key('profile-section-diet')), findsOneWidget);
  });

  testWidgets('shows gender, age, height, weight values', (tester) async {
    await tester.pumpWidget(
      buildProfileScreen(AsyncValue.data(_testProfile)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Male'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('175.0'), findsOneWidget);
    expect(find.text('70.0'), findsOneWidget);
  });

  testWidgets('tapping weight edit button shows inline TextField', (tester) async {
    await tester.pumpWidget(
      buildProfileScreen(AsyncValue.data(_testProfile)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-edit-weight')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-input-weight')), findsOneWidget);
    expect(find.byKey(const Key('profile-confirm-weight')), findsOneWidget);
    expect(find.byKey(const Key('profile-cancel-weight')), findsOneWidget);
  });

  testWidgets('tapping cancel after edit restores read-only view', (tester) async {
    await tester.pumpWidget(
      buildProfileScreen(AsyncValue.data(_testProfile)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-edit-weight')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-cancel-weight')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-input-weight')), findsNothing);
    expect(find.byKey(const Key('profile-edit-weight')), findsOneWidget);
  });

  testWidgets('occupation section shows edit button', (tester) async {
    await tester.pumpWidget(
      buildProfileScreen(AsyncValue.data(_testProfile)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-edit-occupation')), findsOneWidget);
  });

  testWidgets('shows logout button', (tester) async {
    await tester.pumpWidget(
      buildProfileScreen(AsyncValue.data(_testProfile)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logout-button')), findsOneWidget);
  });
}
```

**Step 2: Run tests — expect them to FAIL (screen not yet implemented)**

```bash
cd /Users/y/IdeaProjects/WiseDiet/client
flutter test test/features/history/profile_screen_test.dart
```

Expected: FAIL — missing keys, no profileProvider integration.

**Step 3: Commit the failing tests**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add client/test/features/history/profile_screen_test.dart
git commit -m "test: add failing widget tests for ProfileScreen"
```

---

## Task 12: Client — Implement `ProfileScreen`

Implement the full `ProfileScreen` to make all tests pass.

**Files:**
- Modify: `client/lib/features/history/screens/profile_screen.dart`

**Step 1: Replace the minimal ProfileScreen with the full implementation**

Key structural requirements (must include all test keys):
- Wrap in `ConsumerWidget`
- Watch `profileProvider`
- On loading: return `Scaffold` with `CircularProgressIndicator`
- On error: show error message with retry button
- On data: render `ListView` with four `Card` sections

Each section is a `Card` with a `Column` of `_ProfileFieldRow` widgets. The `_ProfileFieldRow` takes:
- `editKey`: the `Key` for the edit icon button
- `inputKey`: the `Key` for the `TextField` (shown during editing)
- `confirmKey` / `cancelKey`: for save/discard buttons
- `label`: string label
- `value`: display value
- `unit`: optional unit suffix
- `keyboardType`: `TextInputType`
- `onSave`: `Function(String)` callback

State: use a `StatefulConsumerWidget` (or `ConsumerStatefulWidget`) with a `Map<String, bool> _editing` and a `Map<String, TextEditingController> _controllers` to track which field is in edit mode.

The full implementation structure:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_controller.dart';
import '../../onboarding/providers/tag_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Map of field name -> whether it's in edit mode
  final Map<String, bool> _editing = {};
  // Map of field name -> controller (created on demand)
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(String field, String initialValue) {
    return _controllers.putIfAbsent(field, () => TextEditingController(text: initialValue));
  }

  bool _isEditing(String field) => _editing[field] == true;

  void _startEditing(String field) => setState(() => _editing[field] = true);

  void _cancelEditing(String field) {
    setState(() {
      _editing[field] = false;
      _controllers[field]?.dispose();
      _controllers.remove(field);
    });
  }

  Future<void> _saveField(String field, Map<String, dynamic> patch) async {
    await ref.read(profileProvider.notifier).updateField(patch);
    if (mounted) setState(() => _editing[field] = false);
  }

  void _showTagsBottomSheet({
    required String field,
    required String title,
    required Set<int> currentIds,
    required Future<List<dynamic>> Function() loadTags,
    required String Function(dynamic tag) getLabel,
    required int Function(dynamic tag) getId,
  }) {
    // Show modal bottom sheet for tag selection
    // On confirm: call _saveField with updated comma-separated IDs
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.profileSaveError),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section: Basic Info
            _buildSectionCard(
              key: const Key('profile-section-basic-info'),
              title: l10n.profileSectionBasicInfo,
              children: [
                _buildNumericField(
                  field: 'age',
                  label: l10n.profileFieldAge,
                  value: profile.age?.toString() ?? '-',
                  unit: l10n.unitYears,
                  onSave: (v) => _saveField('age', {'age': int.parse(v)}),
                ),
                _buildNumericField(
                  field: 'height',
                  label: l10n.profileFieldHeight,
                  value: profile.height?.toString() ?? '-',
                  unit: l10n.unitCm,
                  onSave: (v) => _saveField('height', {'height': double.parse(v)}),
                ),
                _buildNumericField(
                  field: 'weight',
                  label: l10n.profileFieldWeight,
                  value: profile.weight?.toString() ?? '-',
                  unit: l10n.unitKg,
                  onSave: (v) => _saveField('weight', {'weight': double.parse(v)}),
                ),
                _buildGenderField(profile, l10n),
              ],
            ),
            const SizedBox(height: 12),

            // Section: Household
            _buildSectionCard(
              key: const Key('profile-section-household'),
              title: l10n.profileSectionHousehold,
              children: [
                _buildNumericField(
                  field: 'familyMembers',
                  label: l10n.profileFieldFamilyMembers,
                  value: profile.familyMembers.toString(),
                  unit: l10n.unitPersons,
                  onSave: (v) => _saveField('familyMembers', {'familyMembers': int.parse(v)}),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Section: Occupation Tags
            _buildSectionCard(
              key: const Key('profile-section-occupation'),
              title: l10n.profileSectionOccupation,
              children: [
                _buildTagsField(
                  editKey: const Key('profile-edit-occupation'),
                  label: l10n.profileFieldOccupationTags,
                  tagIds: profile.occupationTags,
                  onEdit: () {/* open bottom sheet */},
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Section: Diet & Allergies
            _buildSectionCard(
              key: const Key('profile-section-diet'),
              title: l10n.profileSectionDiet,
              children: [
                _buildTagsField(
                  editKey: const Key('profile-edit-allergens'),
                  label: l10n.profileFieldAllergens,
                  tagIds: profile.allergenTagIds,
                  onEdit: () {/* open bottom sheet */},
                ),
                _buildTagsField(
                  editKey: const Key('profile-edit-dietary'),
                  label: l10n.profileFieldDietaryPreferences,
                  tagIds: profile.dietaryPreferenceTagIds,
                  onEdit: () {/* open bottom sheet */},
                ),
                _buildCustomAvoidField(profile, l10n),
              ],
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 8),

            // Logout
            OutlinedButton.icon(
              key: const Key('logout-button'),
              onPressed: () => _showLogoutDialog(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(l10n.profileLogout),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required Key key,
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.primary,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNumericField({
    required String field,
    required String label,
    required String value,
    required String unit,
    required Future<void> Function(String) onSave,
  }) {
    final editing = _isEditing(field);
    if (editing) {
      final controller = _controllerFor(field, value);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey))),
            Expanded(
              child: TextField(
                key: Key('profile-input-$field'),
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  suffixText: unit,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
            ),
            IconButton(
              key: Key('profile-confirm-$field'),
              icon: const Icon(Icons.check, color: AppTheme.primary, size: 20),
              onPressed: () => onSave(controller.text.trim()),
            ),
            IconButton(
              key: Key('profile-cancel-$field'),
              icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error, size: 20),
              onPressed: () => _cancelEditing(field),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey))),
          Expanded(
            child: Text(
              '$value $unit',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            key: Key('profile-edit-$field'),
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            onPressed: () => _startEditing(field),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderField(profile, l10n) {
    // Gender inline radio — similar pattern to _buildNumericField
    // Shows "Male"/"Female"/"Other" chips when editing
    // TODO: implement inline radio selection
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(l10n.profileFieldGender, style: const TextStyle(fontSize: 14, color: Colors.grey))),
          Expanded(
            child: Text(
              profile.gender ?? '-',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            key: const Key('profile-edit-gender'),
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            onPressed: () => _startEditing('gender'),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsField({
    required Key editKey,
    required String label,
    required Set<int> tagIds,
    required VoidCallback onEdit,
  }) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Expanded(
            child: tagIds.isEmpty
                ? Text(l10n.profileNoTags,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    children: tagIds.map((id) => Chip(
                      label: Text('$id', style: const TextStyle(fontSize: 11)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    )).toList(),
                  ),
          ),
          IconButton(
            key: editKey,
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAvoidField(profile, l10n) {
    final items = profile.customAvoidedIngredients as List<String>;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(l10n.profileFieldCustomAvoid, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              items.isEmpty ? l10n.profileNoCustomAvoid : items.join('、'),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            key: const Key('profile-edit-customAvoid'),
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            onPressed: () {/* open bottom sheet */},
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileLogoutConfirmTitle),
        content: Text(l10n.profileLogoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.profileLogoutConfirmCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authControllerProvider.notifier).logout();
            },
            child: Text(l10n.profileLogoutConfirmAction),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Run the widget tests**

```bash
cd /Users/y/IdeaProjects/WiseDiet/client
flutter test test/features/history/profile_screen_test.dart
```

Expected: All tests PASS.

**Step 3: Run all client tests**

```bash
cd /Users/y/IdeaProjects/WiseDiet/client
flutter test
```

Expected: All pass.

**Step 4: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add client/lib/features/history/screens/profile_screen.dart
git commit -m "feat: implement ProfileScreen with inline editing and profileProvider"
```

---

## Task 13: Client — Tag Bottom Sheet for Inline Editing

Wire up the occupation, allergen, and dietary preference tag editing via `BottomSheet`. This replaces the `{/* open bottom sheet */}` placeholders.

**Files:**
- Modify: `client/lib/features/history/screens/profile_screen.dart`

**Step 1: Write a widget test for the occupation tag bottom sheet**

Add to `client/test/features/history/profile_screen_test.dart`:

```dart
testWidgets('tapping occupation edit opens bottom sheet', (tester) async {
  await tester.pumpWidget(
    buildProfileScreen(AsyncValue.data(_testProfile)),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('profile-edit-occupation')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('profile-tag-bottom-sheet')), findsOneWidget);
});
```

**Step 2: Run test to see it fail**

```bash
cd /Users/y/IdeaProjects/WiseDiet/client
flutter test test/features/history/profile_screen_test.dart -k "bottom sheet"
```

**Step 3: Implement the bottom sheet helper in ProfileScreen**

Replace `{/* open bottom sheet */}` placeholders with calls to `_showTagBottomSheet`. Add this method:

```dart
Future<void> _showTagBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Future<List<T>> Function() loadTags,
  required int Function(T) getId,
  required String Function(T) getLabel,
  required String? Function(T) getEmoji,
  required Set<int> selectedIds,
  required Future<void> Function(Set<int>) onConfirm,
  bool isAllergen = false,
}) async {
  Set<int> current = {...selectedIds};

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      key: const Key('profile-tag-bottom-sheet'),
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scrollController) => StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onConfirm(current);
                    },
                    child: const Text('确认', style: TextStyle(color: AppTheme.primary)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tag grid
            Expanded(
              child: FutureBuilder<List<T>>(
                future: loadTags(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final tags = snap.data!;
                  return GridView.count(
                    controller: scrollController,
                    crossAxisCount: 3,
                    padding: const EdgeInsets.all(16),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    children: tags.map((tag) {
                      final id = getId(tag);
                      final selected = current.contains(id);
                      return GestureDetector(
                        onTap: () => setSheetState(() {
                          if (selected) {
                            current = {...current}..remove(id);
                          } else {
                            current = {...current, id};
                          }
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? (isAllergen ? Colors.red.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? (isAllergen ? Colors.red : AppTheme.primary)
                                  : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(getEmoji(tag) ?? '', style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(getLabel(tag),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

For occupation tags call site:
```dart
onPressed: () => _showTagBottomSheet<OccupationTag>(
  context: context,
  title: l10n.profileSectionOccupation,
  loadTags: () => ref.read(occupationTagsProvider.future),
  getId: (t) => t.id,
  getLabel: (t) => t.label,
  getEmoji: (t) => t.icon,
  selectedIds: profile.occupationTags,
  onConfirm: (ids) => _saveField('occupationTagIds',
      {'occupationTagIds': ids.join(',')}),
),
```

**Step 4: Run all tests**

```bash
cd /Users/y/IdeaProjects/WiseDiet/client
flutter test
```

Expected: All pass.

**Step 5: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git add client/lib/features/history/screens/profile_screen.dart \
        client/test/features/history/profile_screen_test.dart
git commit -m "feat: add tag bottom sheet for occupation, allergen, dietary preference editing"
```

---

## Task 14: Final Verification

**Step 1: Run all server tests**

```bash
cd /Users/y/IdeaProjects/WiseDiet/server
./mvnw test --timeout 120
```

Expected: All pass, no regressions.

**Step 2: Run all client tests**

```bash
cd /Users/y/IdeaProjects/WiseDiet/client
flutter test
```

Expected: All pass.

**Step 3: Confirm design file is in place**

```bash
ls /Users/y/IdeaProjects/WiseDiet/design/13_profile/
```

Expected: `code.html` present.

**Step 4: Commit with summary if anything was missed**

```bash
cd /Users/y/IdeaProjects/WiseDiet
git log --oneline -12
```

Review commits, then done.
