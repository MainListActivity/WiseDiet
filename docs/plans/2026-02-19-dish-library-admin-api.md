# 菜品库与管理后台 API 实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 建立独立的菜品主库表（`dish_library`），提供管理员 CRUD API，并搭配 HTMX + Tailwind CSS 的轻量管理后台页面，管理员通过现有 Google OAuth 登录后访问。

**Architecture:**
- 新增 `dish_library` 表作为菜品主库（与现有 `dishes` 推荐结果表完全分开）
- `SecurityConfig` 新增 `/admin/ui/**` 路径，要求 ADMIN 角色（通过 admin_whitelist 白名单判断）
- 管理后台使用 HTMX + Tailwind CSS，Spring Boot 直接返回 HTML 片段（Server-Side Rendering）
- 管理员身份识别：Google OAuth 登录后检查 admin_whitelist，若存在则签发带 `ADMIN` role 的 JWT（修改 OAuthService）

**Tech Stack:** Spring Boot 4 WebFlux, R2DBC/PostgreSQL, Spring Security, Thymeleaf（服务端渲染 HTML）, HTMX, Tailwind CSS CDN

---

## 重要背景

现有 `dishes` 表是**推荐结果表**（关联 `meal_plans`，每次推荐都会插入新行）。
本计划新建 `dish_library` 表作为**菜品主库**，两者职责分离：

| 表 | 用途 |
|---|---|
| `dish_library` | 管理员维护的菜品主库，LLM 从此选菜 |
| `dishes` | 每日推荐结果，关联 meal_plans，引用 dish_library |

---

## Task 1: 新增 dish_library 表结构

**Files:**
- Modify: `server/src/main/resources/schema.sql`

**Step 1: 在 schema.sql 末尾追加建表 SQL**

```sql
-- 菜品主库：管理员维护的菜品数据，LLM 从此选菜推荐
CREATE TABLE IF NOT EXISTS "dish_library" (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    category    VARCHAR(30)  NOT NULL,     -- 对应前端图片 key，如 meat_red / veggie_leafy
    difficulty  INT          NOT NULL DEFAULT 2, -- 1-3: 易/中/难
    prep_min    INT          NOT NULL DEFAULT 5,
    cook_min    INT          NOT NULL DEFAULT 15,
    servings    INT          NOT NULL DEFAULT 2,
    ingredients JSONB        NOT NULL,     -- [{"item":"虾仁","amount":200,"unit":"g"},...]
    steps       JSONB        NOT NULL,     -- ["步骤1...","步骤2..."]
    nutrient_tags JSONB,                  -- ["高蛋白","低GI"]
    nutrients   JSONB,                    -- {"protein_g":20,"carb_g":10,"fat_g":5,"calories":200}
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);
```

**Step 2: 无需运行测试，此步骤仅修改 schema，后续 Task 的 TestContainers 会自动应用**

**Step 3: Commit**

```bash
git add server/src/main/resources/schema.sql
git commit -m "feat: add dish_library table to schema"
```

---

## Task 2: 创建 DishLibrary Entity 和 Repository

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/model/DishLibrary.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/repository/DishLibraryRepository.java`

**Step 1: 创建 DishLibrary Entity**

```java
package cn.cuckoox.wisediet.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("dish_library")
public class DishLibrary {
    @Id
    private Long id;
    private String name;
    private String category;
    private Integer difficulty;
    private Integer prepMin;
    private Integer cookMin;
    private Integer servings;
    private String ingredients; // JSON 存为 String，R2DBC 不直接支持 JSONB 对象映射
    private String steps;
    private String nutrientTags;
    private String nutrients;
    private Boolean isActive;
    private LocalDateTime createdAt;
}
```

**Step 2: 创建 DishLibraryRepository**

```java
package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.DishLibrary;
import org.springframework.data.domain.Pageable;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface DishLibraryRepository extends ReactiveCrudRepository<DishLibrary, Long> {

    @Query("SELECT * FROM dish_library WHERE is_active = true ORDER BY id LIMIT :#{#pageable.pageSize} OFFSET :#{#pageable.offset}")
    Flux<DishLibrary> findAllActive(Pageable pageable);

    @Query("SELECT COUNT(*) FROM dish_library WHERE is_active = true")
    Mono<Long> countActive();

    @Query("SELECT * FROM dish_library ORDER BY id LIMIT :#{#pageable.pageSize} OFFSET :#{#pageable.offset}")
    Flux<DishLibrary> findAllPaged(Pageable pageable);

    @Query("SELECT COUNT(*) FROM dish_library")
    Mono<Long> countAll();
}
```

**Step 3: Commit**

```bash
git add server/src/main/java/cn/cuckoox/wisediet/model/DishLibrary.java \
        server/src/main/java/cn/cuckoox/wisediet/repository/DishLibraryRepository.java
git commit -m "feat: add DishLibrary entity and repository"
```

---

## Task 3: 修改 OAuthService 支持 ADMIN 角色 JWT

**背景:** 登录时检查 `admin_whitelist`，若用户在白名单中，则在 JWT claims 中加入 `role=ADMIN`。

**Files:**
- Modify: `server/src/main/java/cn/cuckoox/wisediet/service/OAuthService.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/service/JwtService.java`

**Step 1: 编写集成测试（先写测试）**

在 `server/src/test/java/cn/cuckoox/wisediet/` 新建 `AdminLoginIntegrationTest.java`：

```java
package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.controller.dto.AuthTokenResponse;
import cn.cuckoox.wisediet.controller.dto.OAuthLoginRequest;
import cn.cuckoox.wisediet.model.AdminWhitelist;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.AdminWhitelistRepository;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.time.Duration;

class AdminLoginIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AdminWhitelistRepository adminWhitelistRepository;

    @Autowired
    private SessionStore sessionStore;

    @Autowired
    private JwtService jwtService;

    // AbstractIntegrationTest 的 mock OAuth server 返回邮箱 u@test.com，provider_user_id = provider-id-1
    // 此测试：将该用户加入白名单，登录后验证返回的 token 中 role=ADMIN

    @Test
    void shouldReturnAdminRoleInToken_whenUserIsInAdminWhitelist() {
        // Given: 先让用户登录一次（让 user 记录存在），再加白名单，再重新登录
        String state = "test-state-admin";

        Mono<Void> setup = sessionStore.saveOAuthState(state)
                .then(userRepository.save(new User(null, "u@test.com", "google", "provider-id-1", 0)))
                .flatMap(user -> adminWhitelistRepository.save(new AdminWhitelist(null, user.getId())))
                .then();

        StepVerifier.create(setup).verifyComplete();

        // When: 用 mock OAuth code 登录（AbstractIntegrationTest 的 mock server 固定返回 provider-id-1）
        AuthTokenResponse response = webTestClient.post()
                .uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("mock-code", state))
                .exchange()
                .expectStatus().isOk()
                .returnResult(AuthTokenResponse.class)
                .getResponseBody()
                .blockFirst(Duration.ofSeconds(5));

        // Then: token 中包含 role=ADMIN
        assert response != null;
        String role = jwtService.extractRole(response.accessToken());
        assert "ADMIN".equals(role) : "Expected ADMIN role but got: " + role;
    }

    @Test
    void shouldReturnUserRoleInToken_whenUserIsNotInAdminWhitelist() {
        String state = "test-state-user";

        Mono<Void> setup = sessionStore.saveOAuthState(state).then();
        StepVerifier.create(setup).verifyComplete();

        AuthTokenResponse response = webTestClient.post()
                .uri("/api/auth/google")
                .bodyValue(new OAuthLoginRequest("mock-code", state))
                .exchange()
                .expectStatus().isOk()
                .returnResult(AuthTokenResponse.class)
                .getResponseBody()
                .blockFirst(Duration.ofSeconds(5));

        assert response != null;
        String role = jwtService.extractRole(response.accessToken());
        assert "USER".equals(role) : "Expected USER role but got: " + role;
    }
}
```

**Step 2: 运行测试，验证 FAIL（因为 JwtService 没有 extractRole 方法）**

```bash
cd server && mvn test -pl . -Dtest=AdminLoginIntegrationTest -q 2>&1 | tail -20
```

Expected: FAIL，`extractRole` 方法不存在

**Step 3: 修改 JwtService，在 createAccessToken 增加 role 参数，并新增 extractRole 方法**

找到 `JwtService.java`，修改 `createAccessToken` 签名为 `createAccessToken(Long userId, String role)`，并新增 `extractRole`：

```java
// 修改 createAccessToken 方法（增加 role 参数）
public Mono<String> createAccessToken(Long userId, String role) {
    return Mono.fromCallable(() -> {
        String jti = UUID.randomUUID().toString();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("jti", jti)
                .claim("role", role)          // 新增 role claim
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + jwtProperties.expirationMs()))
                .signWith(getSigningKey())
                .compact();
    });
}

// 新增 extractRole 方法
public String extractRole(String token) {
    return getClaims(token).get("role", String.class);
}
```

注意：`createAccessToken(Long userId)` 原有调用需同步修改（AdminSessionController 测试用到），可保留重载方法：
```java
public Mono<String> createAccessToken(Long userId) {
    return createAccessToken(userId, "USER");
}
```

**Step 4: 修改 OAuthService.login()，登录时查询 admin_whitelist 判断 role**

在 OAuthService 中注入 `AdminWhitelistRepository`，修改 login 方法：

```java
// 注入
private final AdminWhitelistRepository adminWhitelistRepository;

// 在构造函数中添加参数
public OAuthService(..., AdminWhitelistRepository adminWhitelistRepository) {
    ...
    this.adminWhitelistRepository = adminWhitelistRepository;
}

// 修改 login 方法中的 jwtService.createAccessToken 调用：
// 原来：
.flatMap(user -> jwtService.createAccessToken(user.getId())
// 改为：
.flatMap(user -> adminWhitelistRepository.existsByUserId(user.getId())
        .flatMap(isAdmin -> jwtService.createAccessToken(user.getId(), isAdmin ? "ADMIN" : "USER"))
```

同时在 `AdminWhitelistRepository` 中新增：
```java
Mono<Boolean> existsByUserId(Long userId);
```

**Step 5: 运行测试，验证通过**

```bash
cd server && mvn test -pl . -Dtest=AdminLoginIntegrationTest -q 2>&1 | tail -20
```

Expected: PASS

**Step 6: Commit**

```bash
git add server/src/main/java/cn/cuckoox/wisediet/service/JwtService.java \
        server/src/main/java/cn/cuckoox/wisediet/service/OAuthService.java \
        server/src/main/java/cn/cuckoox/wisediet/repository/AdminWhitelistRepository.java \
        server/src/test/java/cn/cuckoox/wisediet/AdminLoginIntegrationTest.java
git commit -m "feat: embed ADMIN role in JWT for admin_whitelist users"
```

---

## Task 4: 菜品库 CRUD API（`/api/admin/dishes`）

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/dto/DishLibraryRequest.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/dto/DishLibraryResponse.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/service/DishLibraryService.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/DishLibraryController.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/config/SecurityConfig.java`

**Step 1: 编写集成测试**

新建 `server/src/test/java/cn/cuckoox/wisediet/DishLibraryIntegrationTest.java`：

```java
package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.AdminWhitelist;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.AdminWhitelistRepository;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.time.Duration;
import java.util.Map;

class DishLibraryIntegrationTest extends AbstractIntegrationTest {

    @Autowired private UserRepository userRepository;
    @Autowired private AdminWhitelistRepository adminWhitelistRepository;
    @Autowired private JwtService jwtService;
    @Autowired private SessionStore sessionStore;

    private String createAdminToken() {
        User admin = userRepository.save(new User(null, "admin2@test.com", "google", "admin-pid", 0))
                .flatMap(u -> adminWhitelistRepository.save(new AdminWhitelist(null, u.getId())).thenReturn(u))
                .block(Duration.ofSeconds(5));
        String token = jwtService.createAccessToken(admin.getId(), "ADMIN").block(Duration.ofSeconds(5));
        sessionStore.saveSession(jwtService.extractJti(token), admin.getId(), Duration.ofMinutes(15))
                .block(Duration.ofSeconds(5));
        return token;
    }

    @Test
    void shouldReturn401_whenNotAuthenticated() {
        webTestClient.get().uri("/api/admin/dishes")
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void shouldReturn403_whenNonAdminAccesses() {
        User user = userRepository.save(new User(null, "plain@test.com", "google", "plain-pid", 0))
                .block(Duration.ofSeconds(5));
        String token = jwtService.createAccessToken(user.getId(), "USER").block(Duration.ofSeconds(5));
        sessionStore.saveSession(jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                .block(Duration.ofSeconds(5));

        webTestClient.get().uri("/api/admin/dishes")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isForbidden();
    }

    @Test
    void shouldCreateAndListDish_whenAdmin() {
        String token = createAdminToken();

        Map<String, Object> request = Map.of(
                "name", "番茄炒蛋",
                "category", "veggie_mixed",
                "difficulty", 1,
                "prepMin", 5,
                "cookMin", 10,
                "servings", 2,
                "ingredients", "[{\"item\":\"番茄\",\"amount\":200,\"unit\":\"g\"},{\"item\":\"鸡蛋\",\"amount\":3,\"unit\":\"个\"}]",
                "steps", "[\"番茄切块\",\"打蛋\",\"炒制\"]",
                "nutrientTags", "[\"高蛋白\"]",
                "nutrients", "{\"calories\":150}"
        );

        // Create
        webTestClient.post().uri("/api/admin/dishes")
                .header("Authorization", "Bearer " + token)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .expectBody()
                .jsonPath("$.id").exists()
                .jsonPath("$.name").isEqualTo("番茄炒蛋");

        // List
        webTestClient.get().uri("/api/admin/dishes")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.content[0].name").isEqualTo("番茄炒蛋");
    }

    @Test
    void shouldToggleDishStatus_whenAdmin() {
        String token = createAdminToken();

        // Create dish first
        Map<String, Object> request = Map.of(
                "name", "测试菜",
                "category", "meat_red",
                "difficulty", 2,
                "prepMin", 10,
                "cookMin", 20,
                "servings", 2,
                "ingredients", "[]",
                "steps", "[]"
        );

        Long id = webTestClient.post().uri("/api/admin/dishes")
                .header("Authorization", "Bearer " + token)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .returnResult(Map.class)
                .getResponseBody()
                .map(m -> ((Number) m.get("id")).longValue())
                .blockFirst(Duration.ofSeconds(5));

        // Disable
        webTestClient.patch().uri("/api/admin/dishes/" + id + "/status")
                .header("Authorization", "Bearer " + token)
                .bodyValue(Map.of("isActive", false))
                .exchange()
                .expectStatus().isOk();

        // Verify disabled in list (only active)
        webTestClient.get().uri("/api/admin/dishes?activeOnly=true")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.content[?(@.name=='测试菜')]").doesNotExist();
    }
}
```

**Step 2: 运行测试，验证 FAIL**

```bash
cd server && mvn test -pl . -Dtest=DishLibraryIntegrationTest -q 2>&1 | tail -20
```

Expected: FAIL，`/api/admin/dishes` 路径不存在，返回 404 或 403

**Step 3: 修改 SecurityConfig，允许 `/api/admin/**` 路径需要认证（ADMIN role 检查放在 Controller 层）**

```java
// 在 authorizeExchange 中，/api/admin/** 改为明确规则
.pathMatchers("/api/auth/**", "/api/tags/**", "/api/hello").permitAll()
.pathMatchers("/api/admin/**").authenticated()   // 认证校验在此，ADMIN role 在 Controller 中校验
.pathMatchers("/api/**").authenticated()
.anyExchange().permitAll()
```

注意：ADMIN role 判断在 Controller 中通过查询 admin_whitelist 实现（复用现有 AdminSessionController 的 validateAdmin 模式）。

**Step 4: 创建 DishLibraryRequest DTO**

```java
package cn.cuckoox.wisediet.controller.dto;

public record DishLibraryRequest(
        String name,
        String category,
        Integer difficulty,
        Integer prepMin,
        Integer cookMin,
        Integer servings,
        String ingredients,
        String steps,
        String nutrientTags,
        String nutrients
) {}
```

**Step 5: 创建 DishLibraryResponse DTO**

```java
package cn.cuckoox.wisediet.controller.dto;

import java.time.LocalDateTime;

public record DishLibraryResponse(
        Long id,
        String name,
        String category,
        Integer difficulty,
        Integer prepMin,
        Integer cookMin,
        Integer servings,
        String ingredients,
        String steps,
        String nutrientTags,
        String nutrients,
        Boolean isActive,
        LocalDateTime createdAt
) {}
```

**Step 6: 创建 DishLibraryService**

```java
package cn.cuckoox.wisediet.service;

import cn.cuckoox.wisediet.controller.dto.DishLibraryRequest;
import cn.cuckoox.wisediet.controller.dto.DishLibraryResponse;
import cn.cuckoox.wisediet.model.DishLibrary;
import cn.cuckoox.wisediet.repository.DishLibraryRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
public class DishLibraryService {

    private final DishLibraryRepository dishLibraryRepository;

    public DishLibraryService(DishLibraryRepository dishLibraryRepository) {
        this.dishLibraryRepository = dishLibraryRepository;
    }

    public Flux<DishLibraryResponse> findAll(int page, int size, boolean activeOnly) {
        PageRequest pageable = PageRequest.of(page, size);
        Flux<DishLibrary> flux = activeOnly
                ? dishLibraryRepository.findAllActive(pageable)
                : dishLibraryRepository.findAllPaged(pageable);
        return flux.map(this::toResponse);
    }

    public Mono<Long> count(boolean activeOnly) {
        return activeOnly ? dishLibraryRepository.countActive() : dishLibraryRepository.countAll();
    }

    public Mono<DishLibraryResponse> findById(Long id) {
        return dishLibraryRepository.findById(id).map(this::toResponse);
    }

    public Mono<DishLibraryResponse> create(DishLibraryRequest request) {
        DishLibrary entity = new DishLibrary();
        entity.setName(request.name());
        entity.setCategory(request.category());
        entity.setDifficulty(request.difficulty() != null ? request.difficulty() : 2);
        entity.setPrepMin(request.prepMin() != null ? request.prepMin() : 5);
        entity.setCookMin(request.cookMin() != null ? request.cookMin() : 15);
        entity.setServings(request.servings() != null ? request.servings() : 2);
        entity.setIngredients(request.ingredients() != null ? request.ingredients() : "[]");
        entity.setSteps(request.steps() != null ? request.steps() : "[]");
        entity.setNutrientTags(request.nutrientTags());
        entity.setNutrients(request.nutrients());
        entity.setIsActive(true);
        return dishLibraryRepository.save(entity).map(this::toResponse);
    }

    public Mono<DishLibraryResponse> update(Long id, DishLibraryRequest request) {
        return dishLibraryRepository.findById(id)
                .flatMap(entity -> {
                    entity.setName(request.name());
                    entity.setCategory(request.category());
                    entity.setDifficulty(request.difficulty());
                    entity.setPrepMin(request.prepMin());
                    entity.setCookMin(request.cookMin());
                    entity.setServings(request.servings());
                    entity.setIngredients(request.ingredients());
                    entity.setSteps(request.steps());
                    entity.setNutrientTags(request.nutrientTags());
                    entity.setNutrients(request.nutrients());
                    return dishLibraryRepository.save(entity);
                })
                .map(this::toResponse);
    }

    public Mono<DishLibraryResponse> updateStatus(Long id, boolean isActive) {
        return dishLibraryRepository.findById(id)
                .flatMap(entity -> {
                    entity.setIsActive(isActive);
                    return dishLibraryRepository.save(entity);
                })
                .map(this::toResponse);
    }

    public Mono<Void> delete(Long id) {
        return dishLibraryRepository.deleteById(id);
    }

    private DishLibraryResponse toResponse(DishLibrary d) {
        return new DishLibraryResponse(
                d.getId(), d.getName(), d.getCategory(),
                d.getDifficulty(), d.getPrepMin(), d.getCookMin(), d.getServings(),
                d.getIngredients(), d.getSteps(), d.getNutrientTags(), d.getNutrients(),
                d.getIsActive(), d.getCreatedAt()
        );
    }
}
```

**Step 7: 创建 DishLibraryController**

```java
package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.controller.dto.DishLibraryRequest;
import cn.cuckoox.wisediet.controller.dto.DishLibraryResponse;
import cn.cuckoox.wisediet.repository.AdminWhitelistRepository;
import cn.cuckoox.wisediet.security.CurrentUserService;
import cn.cuckoox.wisediet.service.DishLibraryService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/dishes")
public class DishLibraryController {

    private final DishLibraryService dishLibraryService;
    private final AdminWhitelistRepository adminWhitelistRepository;
    private final CurrentUserService currentUserService;

    public DishLibraryController(DishLibraryService dishLibraryService,
                                  AdminWhitelistRepository adminWhitelistRepository,
                                  CurrentUserService currentUserService) {
        this.dishLibraryService = dishLibraryService;
        this.adminWhitelistRepository = adminWhitelistRepository;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public Mono<Map<String, Object>> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "false") boolean activeOnly) {
        return requireAdmin()
                .then(Mono.zip(
                        dishLibraryService.findAll(page, size, activeOnly).collectList(),
                        dishLibraryService.count(activeOnly)
                ))
                .map(tuple -> Map.of(
                        "content", tuple.getT1(),
                        "total", tuple.getT2(),
                        "page", page,
                        "size", size
                ));
    }

    @GetMapping("/{id}")
    public Mono<DishLibraryResponse> getById(@PathVariable Long id) {
        return requireAdmin()
                .then(dishLibraryService.findById(id))
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND)));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<DishLibraryResponse> create(@RequestBody DishLibraryRequest request) {
        return requireAdmin().then(dishLibraryService.create(request));
    }

    @PutMapping("/{id}")
    public Mono<DishLibraryResponse> update(@PathVariable Long id, @RequestBody DishLibraryRequest request) {
        return requireAdmin()
                .then(dishLibraryService.update(id, request))
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND)));
    }

    @PatchMapping("/{id}/status")
    public Mono<DishLibraryResponse> updateStatus(@PathVariable Long id, @RequestBody Map<String, Boolean> body) {
        boolean isActive = Boolean.TRUE.equals(body.get("isActive"));
        return requireAdmin()
                .then(dishLibraryService.updateStatus(id, isActive))
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND)));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> delete(@PathVariable Long id) {
        return requireAdmin().then(dishLibraryService.delete(id));
    }

    private Mono<Void> requireAdmin() {
        return currentUserService.currentUserId()
                .flatMap(userId -> adminWhitelistRepository.findByUserId(userId)
                        .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.FORBIDDEN)))
                        .then());
    }
}
```

**Step 8: 运行测试，验证通过**

```bash
cd server && mvn test -pl . -Dtest=DishLibraryIntegrationTest -q 2>&1 | tail -30
```

Expected: PASS

**Step 9: Commit**

```bash
git add server/src/main/java/cn/cuckoox/wisediet/controller/DishLibraryController.java \
        server/src/main/java/cn/cuckoox/wisediet/controller/dto/DishLibraryRequest.java \
        server/src/main/java/cn/cuckoox/wisediet/controller/dto/DishLibraryResponse.java \
        server/src/main/java/cn/cuckoox/wisediet/service/DishLibraryService.java \
        server/src/main/java/cn/cuckoox/wisediet/config/SecurityConfig.java \
        server/src/test/java/cn/cuckoox/wisediet/DishLibraryIntegrationTest.java
git commit -m "feat: add dish library CRUD API (/api/admin/dishes)"
```

---

## Task 5: HTMX + Tailwind 管理后台页面

**背景:** 管理员通过浏览器访问 `/admin/ui/dishes`，Spring Boot 返回 Thymeleaf 渲染的 HTML，HTMX 负责局部刷新，Tailwind CSS CDN 提供样式。

**Files:**
- Modify: `server/pom.xml`（添加 Thymeleaf 依赖）
- Modify: `server/src/main/java/cn/cuckoox/wisediet/config/SecurityConfig.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/AdminUiController.java`
- Create: `server/src/main/resources/templates/admin/dishes.html`
- Create: `server/src/main/resources/templates/admin/dish-row.html`（HTMX 片段）
- Create: `server/src/main/resources/templates/admin/dish-form.html`（HTMX 片段）

**Step 1: 添加 Thymeleaf 依赖到 pom.xml**

在 `<dependencies>` 中添加（Spring WebFlux 使用 thymeleaf-spring6）：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
```

**Step 2: 修改 SecurityConfig，放行 `/admin/ui/**` 路径（使用 Session Cookie 鉴权，不走 JWT Filter）**

管理后台页面采用 **URL 参数传 token** 或 **独立 Session** 方案。

最简单的方案：管理员用 API token（从 app 复制）放在请求 Header 或 Cookie 中。

由于是自己用的工具，采用**最简方案**：页面访问时需在 URL 中携带 `?token=xxx`，后端 Filter 提取并验证。

修改 SecurityConfig：
```java
.pathMatchers("/admin/ui/**").permitAll()  // UI 页面本身不拦截，鉴权在 Controller 层处理
```

**Step 3: 创建 AdminUiController**

```java
package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.repository.AdminWhitelistRepository;
import cn.cuckoox.wisediet.service.DishLibraryService;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Controller
@RequestMapping("/admin/ui")
public class AdminUiController {

    private final DishLibraryService dishLibraryService;
    private final JwtService jwtService;
    private final SessionStore sessionStore;
    private final AdminWhitelistRepository adminWhitelistRepository;

    public AdminUiController(DishLibraryService dishLibraryService,
                              JwtService jwtService,
                              SessionStore sessionStore,
                              AdminWhitelistRepository adminWhitelistRepository) {
        this.dishLibraryService = dishLibraryService;
        this.jwtService = jwtService;
        this.sessionStore = sessionStore;
        this.adminWhitelistRepository = adminWhitelistRepository;
    }

    @GetMapping("/dishes")
    public Mono<String> dishList(@RequestParam String token,
                                  @RequestParam(defaultValue = "0") int page,
                                  Model model) {
        return validateAdminToken(token)
                .then(dishLibraryService.findAll(page, 20, false).collectList()
                        .zipWith(dishLibraryService.count(false))
                        .doOnNext(tuple -> {
                            model.addAttribute("dishes", tuple.getT1());
                            model.addAttribute("total", tuple.getT2());
                            model.addAttribute("page", page);
                            model.addAttribute("token", token);
                        }))
                .thenReturn("admin/dishes");
    }

    // HTMX: 返回新增表单片段
    @GetMapping("/dishes/new")
    public Mono<String> newForm(@RequestParam String token, Model model) {
        return validateAdminToken(token)
                .doOnSuccess(v -> model.addAttribute("token", token))
                .thenReturn("admin/dish-form");
    }

    // HTMX: 提交新增
    @PostMapping("/dishes")
    public Mono<String> create(@RequestParam String token,
                                @ModelAttribute DishFormData form,
                                Model model) {
        return validateAdminToken(token)
                .then(dishLibraryService.create(form.toRequest()))
                .flatMap(dish -> dishLibraryService.findAll(0, 20, false).collectList()
                        .zipWith(dishLibraryService.count(false))
                        .doOnNext(tuple -> {
                            model.addAttribute("dishes", tuple.getT1());
                            model.addAttribute("total", tuple.getT2());
                            model.addAttribute("page", 0);
                            model.addAttribute("token", token);
                        }))
                .thenReturn("admin/dish-table :: table-body");
    }

    // HTMX: 切换启用/禁用状态
    @PostMapping("/dishes/{id}/toggle")
    public Mono<String> toggleStatus(@PathVariable Long id,
                                      @RequestParam String token,
                                      Model model) {
        return validateAdminToken(token)
                .then(dishLibraryService.findById(id))
                .flatMap(dish -> dishLibraryService.updateStatus(id, !dish.isActive()))
                .doOnNext(updated -> model.addAttribute("dish", updated))
                .thenReturn("admin/dish-table :: dish-row");
    }

    private Mono<Void> validateAdminToken(String token) {
        try {
            Long userId = Long.parseLong(jwtService.extractUserId(token));
            String jti = jwtService.extractJti(token);
            return sessionStore.exists(jti)
                    .flatMap(exists -> {
                        if (!exists) return Mono.error(new ResponseStatusException(HttpStatus.UNAUTHORIZED));
                        return adminWhitelistRepository.findByUserId(userId)
                                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.FORBIDDEN)))
                                .then();
                    });
        } catch (Exception e) {
            return Mono.error(new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        }
    }
}
```

**Step 4: 创建菜品列表页面 `templates/admin/dishes.html`**

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org" lang="zh">
<head>
    <meta charset="UTF-8">
    <title>菜品库管理</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/htmx.org@2.0.3"></script>
</head>
<body class="bg-gray-50 min-h-screen">
<div class="max-w-6xl mx-auto py-8 px-4">
    <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-800">菜品库管理</h1>
        <span class="text-sm text-gray-500">共 <span th:text="${total}">0</span> 道菜</span>
    </div>

    <!-- 新增按钮 -->
    <button class="mb-4 px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 text-sm"
            hx-get="/admin/ui/dishes/new"
            hx-target="#form-area"
            hx-swap="innerHTML"
            th:hx-vals="|{&quot;token&quot;: &quot;${token}&quot;}|">
        + 新增菜品
    </button>

    <!-- 表单区 -->
    <div id="form-area" class="mb-6"></div>

    <!-- 菜品表格 -->
    <div id="dish-table">
        <table class="w-full bg-white rounded shadow text-sm">
            <thead class="bg-gray-100 text-gray-600">
            <tr>
                <th class="px-4 py-3 text-left">ID</th>
                <th class="px-4 py-3 text-left">名称</th>
                <th class="px-4 py-3 text-left">分类</th>
                <th class="px-4 py-3 text-left">难度</th>
                <th class="px-4 py-3 text-left">时间(准备+烹饪)</th>
                <th class="px-4 py-3 text-left">状态</th>
                <th class="px-4 py-3 text-left">操作</th>
            </tr>
            </thead>
            <tbody id="table-body" th:fragment="table-body">
            <tr th:each="dish : ${dishes}" th:id="'row-' + ${dish.id}" th:fragment="dish-row">
                <td class="px-4 py-3 text-gray-500" th:text="${dish.id}"></td>
                <td class="px-4 py-3 font-medium" th:text="${dish.name}"></td>
                <td class="px-4 py-3 text-gray-600" th:text="${dish.category}"></td>
                <td class="px-4 py-3" th:text="${dish.difficulty}"></td>
                <td class="px-4 py-3" th:text="${dish.prepMin} + '分钟 + ' + ${dish.cookMin} + '分钟'"></td>
                <td class="px-4 py-3">
                    <span th:if="${dish.isActive}" class="px-2 py-1 bg-green-100 text-green-700 rounded text-xs">启用</span>
                    <span th:unless="${dish.isActive}" class="px-2 py-1 bg-gray-100 text-gray-500 rounded text-xs">禁用</span>
                </td>
                <td class="px-4 py-3">
                    <button class="text-xs px-3 py-1 rounded border hover:bg-gray-50"
                            th:hx-post="'/admin/ui/dishes/' + ${dish.id} + '/toggle?token=' + ${token}"
                            hx-target="closest tr"
                            hx-swap="outerHTML"
                            th:text="${dish.isActive} ? '禁用' : '启用'">
                    </button>
                </td>
            </tr>
            <tr th:if="${#lists.isEmpty(dishes)}">
                <td colspan="7" class="px-4 py-8 text-center text-gray-400">暂无菜品，点击上方新增</td>
            </tr>
            </tbody>
        </table>
    </div>
</div>
</body>
</html>
```

**Step 5: 创建新增表单片段 `templates/admin/dish-form.html`**

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org" lang="zh">
<body>
<div th:fragment="form" class="bg-white rounded shadow p-6 mb-4">
    <h2 class="text-lg font-semibold mb-4">新增菜品</h2>
    <form hx-post="/admin/ui/dishes"
          hx-target="#table-body"
          hx-swap="outerHTML"
          hx-on::after-request="this.closest('div').remove()"
          class="grid grid-cols-2 gap-4">
        <input type="hidden" name="token" th:value="${token}">

        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">菜品名称 *</label>
            <input name="name" required class="w-full border rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-green-500">
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">分类 *</label>
            <select name="category" required class="w-full border rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-green-500">
                <option value="veggie_leafy">绿叶蔬菜</option>
                <option value="veggie_root">根茎蔬菜</option>
                <option value="veggie_mixed">混合蔬菜</option>
                <option value="meat_red">红肉</option>
                <option value="meat_poultry">禽肉</option>
                <option value="seafood">鱼虾海鲜</option>
                <option value="tofu_egg">豆制品蛋类</option>
                <option value="soup_clear">清汤</option>
                <option value="soup_thick">浓汤</option>
                <option value="staple_rice">米饭主食</option>
                <option value="staple_other">其他主食</option>
            </select>
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">难度 (1-3)</label>
            <input name="difficulty" type="number" min="1" max="3" value="2" class="w-full border rounded px-3 py-2 text-sm">
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">人份数</label>
            <input name="servings" type="number" value="2" class="w-full border rounded px-3 py-2 text-sm">
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">准备时间(分钟)</label>
            <input name="prepMin" type="number" value="10" class="w-full border rounded px-3 py-2 text-sm">
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">烹饪时间(分钟)</label>
            <input name="cookMin" type="number" value="15" class="w-full border rounded px-3 py-2 text-sm">
        </div>
        <div class="col-span-2">
            <label class="block text-sm font-medium text-gray-700 mb-1">食材 (JSON数组)</label>
            <textarea name="ingredients" rows="3" placeholder='[{"item":"虾仁","amount":200,"unit":"g"}]'
                      class="w-full border rounded px-3 py-2 text-sm font-mono focus:outline-none focus:ring-1 focus:ring-green-500"></textarea>
        </div>
        <div class="col-span-2">
            <label class="block text-sm font-medium text-gray-700 mb-1">步骤 (JSON数组)</label>
            <textarea name="steps" rows="3" placeholder='["步骤1...", "步骤2..."]'
                      class="w-full border rounded px-3 py-2 text-sm font-mono focus:outline-none focus:ring-1 focus:ring-green-500"></textarea>
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">营养标签 (JSON数组)</label>
            <input name="nutrientTags" placeholder='["高蛋白","低GI"]' class="w-full border rounded px-3 py-2 text-sm font-mono">
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">营养成分 (JSON对象)</label>
            <input name="nutrients" placeholder='{"calories":200,"protein_g":20}' class="w-full border rounded px-3 py-2 text-sm font-mono">
        </div>

        <div class="col-span-2 flex gap-3 justify-end pt-2">
            <button type="button" onclick="this.closest('#form-area').innerHTML=''"
                    class="px-4 py-2 border rounded text-sm hover:bg-gray-50">取消</button>
            <button type="submit" class="px-4 py-2 bg-green-600 text-white rounded text-sm hover:bg-green-700">保存</button>
        </div>
    </form>
</div>
</body>
</html>
```

**Step 6: 创建 DishFormData 辅助类**

```java
package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.controller.dto.DishLibraryRequest;

public class DishFormData {
    private String name, category, ingredients, steps, nutrientTags, nutrients;
    private Integer difficulty, prepMin, cookMin, servings;

    // getters/setters (Lombok @Data)

    public DishLibraryRequest toRequest() {
        return new DishLibraryRequest(name, category, difficulty, prepMin, cookMin, servings,
                ingredients, steps, nutrientTags, nutrients);
    }
}
```

**Step 7: 验证页面能正常访问**

启动服务后，在浏览器访问（替换为你的 JWT token）：
```
http://localhost:8080/admin/ui/dishes?token=YOUR_JWT_TOKEN
```

**Step 8: Commit**

```bash
git add server/pom.xml \
        server/src/main/java/cn/cuckoox/wisediet/controller/AdminUiController.java \
        server/src/main/java/cn/cuckoox/wisediet/controller/DishFormData.java \
        server/src/main/resources/templates/admin/dishes.html \
        server/src/main/resources/templates/admin/dish-form.html
git commit -m "feat: add HTMX+Tailwind admin UI for dish library management"
```

---

## Task 6: 全量测试验证

**Step 1: 运行所有服务端测试**

```bash
cd server && mvn test -q 2>&1 | tail -30
```

Expected: 所有测试 PASS，BUILD SUCCESS

**Step 2: 如有失败，根据错误信息修复后重新运行**

**Step 3: 最终 Commit（如有修复）**

```bash
git add -A
git commit -m "fix: resolve test failures after dish library implementation"
```

---

## 实现顺序依赖

```
Task 1 (schema)
  → Task 2 (entity/repo)
  → Task 3 (OAuth role)
  → Task 4 (CRUD API)
  → Task 5 (HTMX UI)
  → Task 6 (全量测试)
```

所有 Task 必须串行执行，前一个完成后再开始下一个。
