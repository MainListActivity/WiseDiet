# Client State & Navigation Persistence Design

## Overview

Migrate the Flutter client from a custom AppRouter with manual `Navigator.push()` to **GoRouter** with **SharedPreferences**-based route persistence. Users will be restored to their last viewed page on app restart or after re-login.

## Decisions

- **Routing**: GoRouter (Flutter official, declarative, native redirect guards)
- **Route persistence**: SharedPreferences, storing `last_route` as a path string
- **Token validation**: Local-only check (token exists in SecureStorage), no startup API call
- **Splash screen**: Removed, replaced by native splash; app navigates directly to target page
- **Restore granularity**: Full route path restoration

## Route Definitions

```
/login                          → LoginScreen
/onboarding/basic-info          → BasicInfoScreen
/onboarding/occupation          → OccupationProfileScreen
/onboarding/allergies           → AllergiesRestrictionsScreen
/onboarding/family              → FamilyParamsScreen
/onboarding/loading             → LoadingAnalysisScreen
/onboarding/strategy            → StrategyReportScreen
/home                           → TodaySmartMenuFeedScreen
```

## Route Guard (redirect)

Every navigation triggers the redirect function:

1. No token → redirect to `/login`
2. Token exists + needs onboarding → redirect to onboarding step
3. On `/login` with valid token → read `last_route` → redirect to saved route or `/home`

## State Persistence

| Data | Storage | Notes |
|------|---------|-------|
| accessToken / refreshToken | FlutterSecureStorage (unchanged) | Encrypted |
| Current route path | SharedPreferences (`last_route`) | Written on each navigation to non-login/non-onboarding pages |
| Login status | Derived from token existence | No extra storage |
| Onboarding step | Server 403 response (unchanged) | Not stored locally |

### Persistence Rules

- `last_route` updated only for non-login, non-onboarding pages
- `last_route` is NOT cleared on token expiry (401) — preserved for post-login restoration
- `last_route` IS cleared on explicit logout
- Write is async, non-blocking

## Auth Flow: Login Interception & Restore

### Token expiry during use

1. User on `/home` → API returns 401
2. `onUnauthorized` clears token, auth state → not logged in
3. GoRouter redirect detects no token → `/login`
4. `last_route` still holds `/home`
5. User re-logs in → redirect detects logged in + on `/login` → reads `last_route` → go `/home`

### Cold start

1. App starts, GoRouter initial redirect executes
2. Token exists → read `last_route` → navigate to saved route
3. No token → navigate to `/login`

## Code Changes

### New files

- `lib/app/router.dart` — GoRouter config, route definitions, redirect logic
- `lib/core/storage/route_storage.dart` — SharedPreferences wrapper for `last_route`

### Modified files

- `pubspec.yaml` — add `go_router`, `shared_preferences`
- `lib/main.dart` — remove Splash, use `MaterialApp.router` + GoRouter
- `lib/features/auth/auth_controller.dart` — clear `last_route` on logout
- `lib/core/network/api_client.dart` — `onUnauthorized` keeps `last_route`
- All screens with `Navigator.push()` — replace with `context.go()` / `context.push()`

### Deleted files

- `lib/features/auth/splash_screen.dart`
- Related splash test files

### Tests

- New: GoRouter redirect logic tests (auth guard, route restoration)
- New: `route_storage` unit tests
- Update: existing page tests for navigation changes

### Unchanged

- Riverpod state management
- AuthState model
- OAuth login implementation
- All page UIs
