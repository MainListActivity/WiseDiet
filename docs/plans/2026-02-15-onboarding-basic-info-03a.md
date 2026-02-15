# Onboarding 03a Basic Info Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Align onboarding step 03a with the design by replacing form inputs with interactive selectors/sliders, integrating household diners into Basic Info, and keeping frontend/backend onboarding data contract consistent.

**Architecture:** Keep onboarding state in Riverpod `onboardingProvider`, move household diners selection into `BasicInfoScreen`, and keep `OccupationProfileScreen` as step 2. Backend continues using reactive `/api/onboarding/profile` endpoint but adds request validation for core fields to enforce the merged 03a payload constraints.

**Tech Stack:** Flutter (Riverpod, flutter_test/integration_test), Spring Boot 3 WebFlux (R2DBC, Bean Validation, StepVerifier).

---

### Task 1: Add failing frontend widget tests for 03a UI contract

**Files:**
- Create: `client/test/features/onboarding/basic_info_screen_test.dart`
- Modify: `client/integration_test/onboarding_flow_test.dart`

**Step 1: Write the failing test**
- Assert 03a includes gender button group (Male/Female/Other), age/height/weight sliders, BMI preview card text, household diners controls, and step indicator (1/4 style segments).
- Assert tapping Next updates provider data and navigates to `OccupationProfileScreen`.

**Step 2: Run test to verify it fails**
- Run: `cd client && flutter test test/features/onboarding/basic_info_screen_test.dart`
- Expected: FAIL because current screen uses dropdown/text fields and lacks new UI elements.

**Step 3: Write minimal implementation**
- Replace `basic_info_screen.dart` structure with design-aligned widgets and semantics/keys for testability.

**Step 4: Run test to verify it passes**
- Run: `cd client && flutter test test/features/onboarding/basic_info_screen_test.dart`
- Expected: PASS.

### Task 2: Add failing backend validation tests for merged 03a payload

**Files:**
- Modify: `server/src/test/java/cn/cuckoox/wisediet/OnboardingApiIntegrationTest.java`

**Step 1: Write the failing test**
- Add test that submits invalid profile values (e.g., unsupported gender or diners out of range) and expects `400 Bad Request`.

**Step 2: Run test to verify it fails**
- Run: `cd server && ./mvnw -Dtest=OnboardingApiIntegrationTest test`
- Expected: FAIL because endpoint currently accepts invalid payloads.

**Step 3: Write minimal implementation**
- Add bean validation annotations on onboarding profile model and enforce valid range/enum-compatible values.

**Step 4: Run test to verify it passes**
- Run: `cd server && ./mvnw -Dtest=OnboardingApiIntegrationTest test`
- Expected: PASS.

### Task 3: Update onboarding navigation and flow after family merge

**Files:**
- Modify: `client/lib/features/onboarding/screens/occupation_profile_screen.dart`
- Modify: `client/integration_test/onboarding_flow_test.dart`

**Step 1: Write failing test expectation**
- Integration flow expects Tag step next action to go to loading screen (not family params page).

**Step 2: Run to verify failure**
- Run: `cd client && flutter test integration_test/onboarding_flow_test.dart`

**Step 3: Minimal implementation**
- Change next navigation destination to `LoadingAnalysisScreen` and keep provider update logic.

**Step 4: Run test to verify pass**
- Run: `cd client && flutter test integration_test/onboarding_flow_test.dart`

### Task 4: Regression verification

**Files:**
- No code changes expected

**Step 1: Run focused frontend tests**
- `cd client && flutter test test/features/onboarding/basic_info_screen_test.dart integration_test/onboarding_flow_test.dart`

**Step 2: Run focused backend tests**
- `cd server && ./mvnw -Dtest=OnboardingApiIntegrationTest,OnboardingIntegrationTest test`

**Step 3: Confirm all green**
- Ensure no failing assertions and no `.block()` usage in tests.
