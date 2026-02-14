# Backend Security Session Hardening Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复后端默认放行问题，建立“默认受保护 + 白名单放行”的鉴权边界，并提供统一的登录态用户获取流程。

**Architecture:** 将 Spring Security 策略改为 allowlist + default deny/require-auth；JWT 过滤器改为在受保护 API 上执行“Token -> jti -> Redis Session -> userId -> User”校验链，最终把 `AuthenticatedUser` 放入 Reactive Security Context。新增 `CurrentUserService` 提供控制器/过滤器统一获取当前用户信息。

**Tech Stack:** Spring Boot WebFlux, Spring Security, Reactor, Redis Reactive, R2DBC, JUnit5 + StepVerifier + WebTestClient

---

### Task 1: 编写失败的安全边界测试（RED）

**Files:**
- Create: `server/src/test/java/cn/cuckoox/wisediet/SecurityBoundaryIntegrationTest.java`

1. 新增测试：未登录访问 `/api/onboarding/profile` 返回 `401`。
2. 新增测试：未登录访问 `/api/tags/occupations` 返回 `200`（公开接口）。
3. 新增测试：未登录访问 `/api/admin/sessions/revoke` 返回 `401`。
4. 运行：`cd server && ./mvnw -Dtest=SecurityBoundaryIntegrationTest test`

### Task 2: 编写失败的“session 获取用户信息”测试（RED）

**Files:**
- Create: `server/src/test/java/cn/cuckoox/wisediet/CurrentUserSessionFlowIntegrationTest.java`

1. 新增测试：构造合法 token + session，调用受保护端点时能通过 session 解析到当前用户并执行业务（admin revoke）。
2. 新增测试：token subject 与 redis session userId 不一致时返回 `401`。
3. 运行：`cd server && ./mvnw -Dtest=CurrentUserSessionFlowIntegrationTest test`

### Task 3: 最小实现使测试通过（GREEN）

**Files:**
- Modify: `server/src/main/java/cn/cuckoox/wisediet/config/SecurityConfig.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/security/JwtAuthenticationFilter.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/service/SessionStore.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/security/AuthenticatedUser.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/security/CurrentUserService.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/controller/AdminSessionController.java`

1. Security 配置改为：仅 auth/tags/hello 公开，其余 `/api/**` 默认需登录。
2. Jwt 过滤器对受保护 API 执行会话校验并注入 `AuthenticatedUser`。
3. `SessionStore` 增加按 jti 读取 userId 接口。
4. 控制器改用 `CurrentUserService` 获取当前用户并执行权限判断。

### Task 4: 回归测试与重构（REFACTOR）

**Files:**
- Modify: `server/src/main/java/cn/cuckoox/wisediet/security/OnboardingGateFilter.java`（如需要统一 current user 获取）
- Modify: 测试代码中不符合 reactive 风格的位置（如存在）

1. 运行：`cd server && ./mvnw test`
2. 若失败，按失败栈最小化修复，不引入额外行为变更。

### Task 5: 更新协作文档

**Files:**
- Modify: `AGENTS.md`

1. 增补后端安全规则：endpoint 分级、默认受保护策略、session 用户信息获取标准流程。
2. 写明新增规范：控制器不得直接解析 token，统一通过 current user service。
