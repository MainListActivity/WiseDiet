# I18n Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add i18n support to both Flutter client and Spring WebFlux server, so adding a new language only requires adding new language-specific files/classes.

**Architecture:** Client uses Flutter gen-l10n with ARB resource files and context extensions. Server uses locale provider strategy + registry, selecting language implementation by `Accept-Language` without changing existing controllers when adding languages.

**Tech Stack:** Flutter 3 (gen-l10n), Spring Boot WebFlux, Reactor Mono/Flux, JUnit + WebTestClient.

---

### Task 1: Client i18n bootstrap

**Files:**
- Modify: `client/pubspec.yaml`
- Create: `client/l10n.yaml`
- Create: `client/lib/l10n/app_en.arb`
- Create: `client/lib/l10n/app_zh.arb`
- Create: `client/lib/l10n/l10n.dart`

**Step 1: Write the failing test**
- Add a widget test expecting Chinese copy for `HelloWidget` under Chinese locale.

**Step 2: Run test to verify it fails**
- Run: `cd client && flutter test test/hello_widget_test.dart`
- Expected: FAIL because widget is hardcoded in English.

**Step 3: Write minimal implementation**
- Enable localization generation and delegates.
- Add English/Chinese ARB translations.
- Add context extension for localized string access.

**Step 4: Run test to verify it passes**
- Run: `cd client && flutter test test/hello_widget_test.dart`
- Expected: PASS.

### Task 2: Client UI text migration

**Files:**
- Modify: `client/lib/main.dart`
- Modify: `client/lib/widgets/hello_widget.dart`
- Modify: `client/lib/features/auth/login_screen.dart`
- Modify: `client/lib/app/router.dart`
- Modify: `client/lib/features/auth/splash_screen.dart`
- Modify: `client/test/features/auth/login_screen_test.dart`

**Step 1: Write the failing test**
- Add/adjust tests to use generated localization keys (default English and Chinese locale scenarios).

**Step 2: Run test to verify it fails**
- Run focused tests and verify expected text mismatches.

**Step 3: Write minimal implementation**
- Replace hardcoded user-facing copy with l10n keys.

**Step 4: Run test to verify it passes**
- Run focused widget tests.

### Task 3: Server i18n strategy registry

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/i18n/LocalizedMessageProvider.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/i18n/EnglishMessageProvider.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/i18n/ChineseMessageProvider.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/i18n/LocalizedMessageService.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/api/HelloController.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/controller/OnboardingController.java`

**Step 1: Write the failing test**
- Add integration tests asserting Chinese response content when `Accept-Language: zh-CN`.

**Step 2: Run test to verify it fails**
- Run: `cd server && ./mvnw -Dtest=HelloControllerI18nIntegrationTest,OnboardingI18nIntegrationTest test`
- Expected: FAIL due hardcoded English response.

**Step 3: Write minimal implementation**
- Implement provider interface + registry service.
- Select provider by locale language tag, fallback to English.
- Keep controller response reactive (`Mono`/`Flux`).

**Step 4: Run test to verify it passes**
- Re-run focused server tests.

### Task 4: Full verification

**Files:**
- Modify as above

**Step 1: Run client regression tests**
- Run: `cd client && flutter test`

**Step 2: Run server regression tests**
- Run: `cd server && ./mvnw test`

**Step 3: Confirm evidence and summarize**
- Report exact commands and outcomes.
