# Today Smart Menu Feed Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement timeline-style Today menu with grouped meal slots, N+1 guidance, nutrition metadata, and floating summary bar across backend and Flutter frontend.

**Architecture:** Expand server `/api/today/recommendations` response to include grouped meal sections and richer dish metadata while preserving reactive flow (Mono/Flux). On Flutter, replace simple list with timeline sections and dish cards rendered from API/domain models, with local selection state driving bottom summary.

**Tech Stack:** Spring Boot WebFlux + R2DBC + Reactor StepVerifier, Flutter 3/Dart widget tests.

---

### Task 1: Server response contract

**Files:**
- Modify: `server/src/test/java/cn/cuckoox/wisediet/TodayApiIntegrationTest.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/controller/dto/MealPlanResponse.java`
- Modify: `server/src/main/java/cn/cuckoox/wisediet/service/TodayService.java`

1. Write failing test for meal-group metadata and 4-meal sections.
2. Run server targeted test and verify fail.
3. Implement DTO + service mock data to satisfy contract.
4. Run test and verify pass.

### Task 2: Flutter timeline UI

**Files:**
- Modify: `client/test/features/today/today_smart_menu_feed_screen_test.dart`
- Modify: `client/lib/features/today/screens/today_smart_menu_feed_screen.dart`

1. Write failing widget tests for timeline sections, N+1 guide, Daily Insight card, and floating progress bar.
2. Run targeted Flutter test and verify fail.
3. Implement timeline UI with grouped dishes, meal color system, image, calories/nutrition tags, selected highlight.
4. Run tests and verify pass.

### Task 3: End-to-end verification

**Files:** none

1. Run server today integration tests.
2. Run client today widget tests.
3. Fix regressions until green.
