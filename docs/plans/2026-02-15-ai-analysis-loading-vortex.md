# AI Analysis Loading Vortex Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade onboarding AI analysis loading page to match Data Vortex design with animated rings, floating tags, progress percentage, grid-dot background, gradient blur and brand signature.

**Architecture:** Keep existing screen navigation/data flow unchanged. Replace center loading widget with a layered visual scene: procedural background painter + animated concentric dashed rings + orbiting tags + deterministic progress ticker. Add test hooks via keys and injectable `autoProcess` / `processingDuration` for stable widget tests.

**Tech Stack:** Flutter 3, Dart, flutter_test, Riverpod (existing), CustomPainter + AnimationController.

---

### Task 1: Red test for required loading design elements

**Files:**
- Create: `client/test/features/onboarding/loading_analysis_screen_test.dart`
- Modify: `client/lib/features/onboarding/screens/loading_analysis_screen.dart`

**Step 1: Write failing test**
- Assert existence of: floating tags (`Muscle Gain`, `Vegan`), progress percent text (`%`), brand text (`POWERED BY WISEDIET AI`), and vortex ring container key.

**Step 2: Run test to verify it fails**
- Run: `cd client && flutter test test/features/onboarding/loading_analysis_screen_test.dart`
- Expected: FAIL because current screen does not render these elements.

### Task 2: Minimal implementation to pass test

**Files:**
- Modify: `client/lib/features/onboarding/screens/loading_analysis_screen.dart`

**Step 1: Add UI layers and animations**
- Grid dots background painter
- Glow/blur gradient layers
- Concentric animated dashed rings
- Floating chip labels
- Progress percentage and progress bar
- Brand footer text

**Step 2: Keep existing async process behavior**
- Preserve `_processData()` flow.
- Add testability parameters only (`autoProcess`, `processingDuration`) without behavior regression.

### Task 3: Verify green and cleanup

**Files:**
- Modify: `client/lib/features/onboarding/screens/loading_analysis_screen.dart`
- Test: `client/test/features/onboarding/loading_analysis_screen_test.dart`

**Step 1: Run focused test**
- Run: `cd client && flutter test test/features/onboarding/loading_analysis_screen_test.dart`
- Expected: PASS.

**Step 2: Run onboarding test set sanity check**
- Run: `cd client && flutter test test/features/onboarding`
- Expected: PASS.
