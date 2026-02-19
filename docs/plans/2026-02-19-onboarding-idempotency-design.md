# Onboarding 幂等性与重复引导修复设计

**日期：** 2026-02-19
**问题：** 用户重新登录后被重复引导到 onboarding 页面；用户再次经过 onboarding 时重复创建 profile

---

## 问题根因

### 问题1：重复引导 onboarding
- 后端登录响应（`AuthTokenResponse`）未携带 `onboardingStep` 字段
- 前端 `google_login.dart` 登录成功后硬编码 `onboardingStep: 1`，不管用户是否已完成
- 结果：老用户每次重新登录都触发 onboarding 跳转

### 问题2：重复创建 profile
- `OnboardingController.saveProfile()` 每次都调用 `repository.save()`（始终插入新行）
- `user_profiles` 表缺少 `UNIQUE(user_id)` 约束，同一用户可有多条记录
- `users.onboarding_step` 在 profile 提交后从未被重置为 0

---

## 方案设计（方案一：登录响应携带 onboardingStep）

**核心原则：后端是唯一真相来源，`onboardingStep` 从后端流向前端，不在前端硬编码。**

---

## 后端改动

### 1. `AuthTokenResponse` 加 `onboardingStep` 字段
```java
record AuthTokenResponse(String accessToken, String refreshToken, int onboardingStep) {}
```

### 2. `OAuthService.login()` 从 user 对象取 `onboardingStep` 放入响应
- 构建 `AuthTokenResponse` 时传入 `user.getOnboardingStep()`

### 3. `OnboardingController.saveProfile()` 改为 upsert + 完成 onboarding
- 先查 `userProfileRepository.findByUserId(userId)`
- 有则更新（设置 existing id），无则新建
- save 成功后调用 `userRepository.completeOnboarding(userId)` 将 `onboarding_step = 0`

### 4. `UserRepository` 加 `completeOnboarding` 方法
```java
@Modifying
@Query("UPDATE users SET onboarding_step = 0 WHERE id = :userId")
Mono<Void> completeOnboarding(@Param("userId") Long userId);
```

### 5. 数据库 migration：`user_profiles` 加唯一约束
```sql
ALTER TABLE user_profiles ADD CONSTRAINT uq_user_profiles_user_id UNIQUE (user_id);
```
> 注意：需要先清理历史重复数据再加约束。在 schema.sql 中同步更新。

---

## 前端改动

### 1. `google_login.dart` / `github_login.dart`
从登录响应中读取 `onboardingStep`，不再硬编码 1：
```dart
final onboardingStep = body['onboardingStep'] as int? ?? 1;
return AuthState(isLoggedIn: true, onboardingStep: onboardingStep, ...);
```

### 2. `auth_controller.dart` 加 `completeOnboarding()` 方法
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

### 3. Onboarding 提交成功后调用 `completeOnboarding()`
- 在 `LoadingAnalysisScreen` 或 onboarding provider 的提交逻辑中，profile 提交成功后调用 `authController.completeOnboarding()`

### 4. 冷启动处理（选项 A）
- 冷启动时默认 `onboardingStep = 0`
- 依赖现有 `OnboardingGateFilter`：首次 API 请求若返回 `403 + X-Error-Code: ONBOARDING_REQUIRED`，则触发 `handleOnboardingRequired()` 跳转
- 无需新增 `/api/auth/me` endpoint

---

## 数据流（修复后）

```
登录流程：
  Frontend → POST /api/auth/google
  Backend  → { accessToken, refreshToken, onboardingStep: 0 或 1 }
  Frontend → AuthState.onboardingStep = 后端值
  Router   → onboardingStep == 0 ? /home : /onboarding/basic-info

Profile 提交流程：
  Frontend → POST /api/onboarding/profile
  Backend  → upsert profile + users.onboarding_step = 0
  Frontend → authController.completeOnboarding() → onboardingStep = 0
  Router   → 允许跳转 /home
```

---

## 测试覆盖要求

### 后端集成测试
1. 老用户登录 → 响应含 `onboardingStep: 0`
2. 新用户登录 → 响应含 `onboardingStep: 1`
3. 同一用户二次提交 profile → 只有一条记录，数据被更新
4. Profile 提交成功后 → `users.onboarding_step = 0`

### 后端单元测试（Service 层）
1. `OAuthService.login()` 返回的 `AuthTokenResponse.onboardingStep` 与 user 一致
2. `saveProfile` upsert 逻辑：有旧 profile 时更新，无时新建

### 前端 Widget/Provider 测试
1. 登录响应 `onboardingStep: 0` → AuthState.onboardingStep = 0，router 不跳转 onboarding
2. 登录响应 `onboardingStep: 1` → AuthState.onboardingStep = 1，router 跳转 onboarding
3. `completeOnboarding()` 调用后 → AuthState.onboardingStep = 0
