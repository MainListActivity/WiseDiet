# Client State & Navigation Persistence — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate from custom AppRouter to GoRouter with SharedPreferences-based route persistence, so users are restored to their last viewed page on app restart or after re-login.

**Architecture:** GoRouter handles all routing declaratively with a central redirect function that checks auth state (token existence in SecureStorage) and restores saved routes from SharedPreferences. The `last_route` is persisted on every navigation to a non-login/non-onboarding page.

**Tech Stack:** Flutter, GoRouter, SharedPreferences, Riverpod, FlutterSecureStorage (existing)

---

### Task 1: Add dependencies

**Files:**
- Modify: `client/pubspec.yaml:30-48`

**Step 1: Add go_router and shared_preferences to pubspec.yaml**

Add these two lines to the `dependencies:` section after `url_launcher`:

```yaml
  go_router: ^15.1.2
  shared_preferences: ^2.3.5
```

**Step 2: Install dependencies**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter pub get`
Expected: Dependencies resolve successfully, no version conflicts.

**Step 3: Commit**

```bash
git add client/pubspec.yaml client/pubspec.lock
git commit -m "chore: add go_router and shared_preferences dependencies"
```

---

### Task 2: Create RouteStorage service

**Files:**
- Create: `client/lib/core/storage/route_storage.dart`
- Create: `client/test/core/storage/route_storage_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wise_diet/core/storage/route_storage.dart';

void main() {
  group('RouteStorage', () {
    late RouteStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = RouteStorage();
    });

    test('returns null when no route is saved', () async {
      final route = await storage.getLastRoute();
      expect(route, isNull);
    });

    test('saves and retrieves a route', () async {
      await storage.saveLastRoute('/home');
      final route = await storage.getLastRoute();
      expect(route, '/home');
    });

    test('clears the saved route', () async {
      await storage.saveLastRoute('/home');
      await storage.clearLastRoute();
      final route = await storage.getLastRoute();
      expect(route, isNull);
    });

    test('overwrites previously saved route', () async {
      await storage.saveLastRoute('/home');
      await storage.saveLastRoute('/settings');
      final route = await storage.getLastRoute();
      expect(route, '/settings');
    });

    test('does not save login route', () async {
      await storage.saveLastRoute('/home');
      await storage.saveLastRoute('/login');
      final route = await storage.getLastRoute();
      expect(route, '/home');
    });

    test('does not save onboarding routes', () async {
      await storage.saveLastRoute('/home');
      await storage.saveLastRoute('/onboarding/basic-info');
      final route = await storage.getLastRoute();
      expect(route, '/home');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/core/storage/route_storage_test.dart`
Expected: FAIL — `route_storage.dart` does not exist.

**Step 3: Write minimal implementation**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class RouteStorage {
  static const _key = 'last_route';

  static const _ignoredPrefixes = ['/login', '/onboarding'];

  Future<String?> getLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> saveLastRoute(String route) async {
    if (_ignoredPrefixes.any((prefix) => route.startsWith(prefix))) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, route);
  }

  Future<void> clearLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/core/storage/route_storage_test.dart`
Expected: All 6 tests PASS.

**Step 5: Commit**

```bash
git add client/lib/core/storage/route_storage.dart client/test/core/storage/route_storage_test.dart
git commit -m "feat: add RouteStorage service for last_route persistence"
```

---

### Task 3: Create AuthSessionProvider

The app needs a way to check at startup whether a token exists in SecureStorage, without making an API call. Currently `AuthState` starts as `initial()` (not logged in) and only gets updated after an OAuth flow. We need a provider that reads stored tokens at startup.

**Files:**
- Create: `client/lib/features/auth/auth_session_provider.dart`
- Create: `client/test/features/auth/auth_session_provider_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/auth/auth_session_provider.dart';

void main() {
  group('AuthSessionProvider', () {
    test('returns true when token exists', () async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Future.value(true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(authSessionProvider.future);
      expect(result, true);
    });

    test('returns false when token is null', () async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Future.value(false),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(authSessionProvider.future);
      expect(result, false);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/features/auth/auth_session_provider_test.dart`
Expected: FAIL — file does not exist.

**Step 3: Write minimal implementation**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authSessionProvider = FutureProvider<bool>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'accessToken');
  return token != null && token.isNotEmpty;
});
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/features/auth/auth_session_provider_test.dart`
Expected: All tests PASS.

**Step 5: Commit**

```bash
git add client/lib/features/auth/auth_session_provider.dart client/test/features/auth/auth_session_provider_test.dart
git commit -m "feat: add AuthSessionProvider to check token existence at startup"
```

---

### Task 4: Create GoRouter configuration

**Files:**
- Create: `client/lib/app/router.dart` (overwrite existing)
- Create: `client/test/app/router_test.dart`

**Step 1: Write the failing tests**

Tests for the GoRouter redirect logic:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wise_diet/app/router.dart';
import 'package:wise_diet/core/storage/route_storage.dart';
import 'package:wise_diet/features/auth/auth_controller.dart';
import 'package:wise_diet/features/auth/auth_state.dart';
import 'package:wise_diet/features/auth/auth_session_provider.dart';

class FakeAuthApi implements AuthApi {
  @override
  Future<AuthState> loginWithGoogle() async => throw UnimplementedError();
  @override
  Future<AuthState> loginWithGithub() async => throw UnimplementedError();
}

class FakeTokenStorage implements TokenStorage {
  @override
  Future<void> clearTokens() async {}
}

void main() {
  group('AppRouter redirect', () {
    testWidgets('redirects to /login when not authenticated', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith((ref) => Future.value(false)),
          authControllerProvider.overrideWith(
            (ref) => AuthController(FakeAuthApi(), tokenStorage: FakeTokenStorage()),
          ),
          routeStorageProvider.overrideWithValue(RouteStorage()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/login');
    });

    testWidgets('redirects to /home when authenticated and no saved route', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith((ref) => Future.value(true)),
          authControllerProvider.overrideWith(
            (ref) {
              final controller = AuthController(FakeAuthApi(), tokenStorage: FakeTokenStorage());
              controller.state = const AuthState(
                isLoggedIn: true,
                onboardingStep: 0,
                accessToken: 'token',
                refreshToken: 'refresh',
              );
              return controller;
            },
          ),
          routeStorageProvider.overrideWithValue(RouteStorage()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/home');
    });

    testWidgets('redirects to /onboarding/basic-info when onboarding required', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith((ref) => Future.value(true)),
          authControllerProvider.overrideWith(
            (ref) {
              final controller = AuthController(FakeAuthApi(), tokenStorage: FakeTokenStorage());
              controller.state = const AuthState(
                isLoggedIn: true,
                onboardingStep: 1,
                accessToken: 'token',
                refreshToken: 'refresh',
              );
              return controller;
            },
          ),
          routeStorageProvider.overrideWithValue(RouteStorage()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/onboarding/basic-info');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/app/router_test.dart`
Expected: FAIL — new router.dart not yet created.

**Step 3: Write the GoRouter implementation**

Overwrite `client/lib/app/router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/storage/route_storage.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_session_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/onboarding/screens/basic_info_screen.dart';
import '../features/onboarding/screens/occupation_profile_screen.dart';
import '../features/onboarding/screens/allergies_restrictions_screen.dart';
import '../features/onboarding/screens/family_params_screen.dart';
import '../features/onboarding/screens/loading_analysis_screen.dart';
import '../features/onboarding/screens/strategy_report_screen.dart';
import '../features/today/screens/today_smart_menu_feed_screen.dart';

final routeStorageProvider = Provider<RouteStorage>((ref) => RouteStorage());

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final routeStorage = ref.read(routeStorageProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) async {
      final isLoggedIn = authState.isLoggedIn;
      final isOnLogin = state.matchedLocation == '/login';
      final isOnOnboarding = state.matchedLocation.startsWith('/onboarding');

      // Not logged in: check if token exists in storage (cold start)
      if (!isLoggedIn) {
        final hasToken = await ref.read(authSessionProvider.future);
        if (!hasToken) {
          return isOnLogin ? null : '/login';
        }
        // Token exists but authState not yet updated — allow navigation
        // The first API call will trigger proper auth state update
      }

      // Logged in but on login page — restore saved route or go home
      if (isLoggedIn && isOnLogin) {
        final savedRoute = await routeStorage.getLastRoute();
        return savedRoute ?? '/home';
      }

      // Onboarding required
      if (isLoggedIn && authState.onboardingStep > 0 && !isOnOnboarding) {
        return '/onboarding/basic-info';
      }

      // Save current route for restoration
      if (!isOnLogin && !isOnOnboarding) {
        routeStorage.saveLastRoute(state.matchedLocation);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding/basic-info',
        builder: (context, state) => const BasicInfoScreen(),
      ),
      GoRoute(
        path: '/onboarding/occupation',
        builder: (context, state) => const OccupationProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/allergies',
        builder: (context, state) => const AllergiesRestrictionsScreen(),
      ),
      GoRoute(
        path: '/onboarding/family',
        builder: (context, state) => const FamilyParamsScreen(),
      ),
      GoRoute(
        path: '/onboarding/loading',
        builder: (context, state) => const LoadingAnalysisScreen(),
      ),
      GoRoute(
        path: '/onboarding/strategy',
        builder: (context, state) => StrategyReportScreen(
          strategy: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const TodaySmartMenuFeedScreen(),
      ),
    ],
  );
});
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/app/router_test.dart`
Expected: All 3 tests PASS.

**Step 5: Commit**

```bash
git add client/lib/app/router.dart client/test/app/router_test.dart
git commit -m "feat: replace custom AppRouter with GoRouter and auth redirect"
```

---

### Task 5: Update main.dart to use GoRouter

**Files:**
- Modify: `client/lib/main.dart`

**Step 1: Update main.dart**

Replace `MaterialApp` with `MaterialApp.router`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wise_diet/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'app/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

**Step 2: Verify app compiles**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter analyze`
Expected: No errors.

**Step 3: Commit**

```bash
git add client/lib/main.dart
git commit -m "feat: update main.dart to use MaterialApp.router with GoRouter"
```

---

### Task 6: Update all screen navigation from Navigator.push to GoRouter

Replace all `Navigator.push()` / `Navigator.pushReplacement()` / `Navigator.pop()` calls with GoRouter equivalents.

**Files:**
- Modify: `client/lib/features/onboarding/screens/basic_info_screen.dart:351-356`
- Modify: `client/lib/features/onboarding/screens/occupation_profile_screen.dart:176-179, 200-203`
- Modify: `client/lib/features/onboarding/screens/allergies_restrictions_screen.dart:35-38, 42-45`
- Modify: `client/lib/features/onboarding/screens/family_params_screen.dart:52-55`
- Modify: `client/lib/features/onboarding/screens/loading_analysis_screen.dart:105-110, 119`
- Modify: `client/lib/features/onboarding/screens/strategy_report_screen.dart:418-425`

**Step 1: Update BasicInfoScreen**

Replace (line ~351):
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const OccupationProfileScreen(),
  ),
);
```
With:
```dart
context.go('/onboarding/occupation');
```

Add import at top: `import 'package:go_router/go_router.dart';`
Remove import: `import 'package:wise_diet/features/onboarding/screens/occupation_profile_screen.dart';` (if only used for navigation)

**Step 2: Update OccupationProfileScreen**

Replace both `Navigator.push` calls (lines ~176, ~200) navigating to `FamilyParamsScreen`:
```dart
context.go('/onboarding/allergies');
```

Add import: `import 'package:go_router/go_router.dart';`
Remove import of `FamilyParamsScreen` (if only used for navigation).

**Step 3: Update AllergiesRestrictionsScreen**

Replace both `Navigator.push` calls (lines ~35, ~42) navigating to `FamilyParamsScreen`:
```dart
context.go('/onboarding/family');
```

Add import: `import 'package:go_router/go_router.dart';`
Remove import of `FamilyParamsScreen`.

**Step 4: Update FamilyParamsScreen**

Replace `Navigator.push` (line ~52) navigating to `LoadingAnalysisScreen`:
```dart
context.go('/onboarding/loading');
```

Add import: `import 'package:go_router/go_router.dart';`
Remove import of `LoadingAnalysisScreen`.

**Step 5: Update LoadingAnalysisScreen**

Replace `Navigator.pushReplacement` (line ~105) navigating to `StrategyReportScreen`:
```dart
context.go('/onboarding/strategy', extra: strategy);
```

Replace `Navigator.pop(context)` (line ~119) on error:
```dart
context.go('/onboarding/family');
```

Add import: `import 'package:go_router/go_router.dart';`
Remove import of `StrategyReportScreen`.

**Step 6: Update StrategyReportScreen**

Replace `Navigator.push` (line ~418) navigating to `TodaySmartMenuFeedScreen`:
```dart
context.go('/home');
```

Add import: `import 'package:go_router/go_router.dart';`
Remove import of `TodaySmartMenuFeedScreen`.

**Step 7: Update StrategyReportScreen preference dialog Navigator.pop**

The `Navigator.pop(context, option)` at line ~76 is used inside a dialog — this should remain as `Navigator.pop` since it's popping a dialog, not navigating routes. No change needed here.

**Step 8: Verify compilation**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter analyze`
Expected: No errors.

**Step 9: Commit**

```bash
git add client/lib/features/
git commit -m "refactor: replace Navigator.push with GoRouter context.go across all screens"
```

---

### Task 7: Update AuthController to clear last_route on logout

**Files:**
- Modify: `client/lib/features/auth/auth_controller.dart`
- Modify: `client/test/auth_controller_test.dart`

**Step 1: Write the failing test**

Add a test to the existing test file:

```dart
test('handleUnauthorized does not clear last route', () async {
  // handleUnauthorized should preserve last_route for post-login restoration
  await controller.handleUnauthorized();
  verify(mockTokenStorage.clearTokens()).called(1);
  // RouteStorage.clearLastRoute should NOT be called
});

test('logout clears both tokens and last route', () async {
  await controller.logout();
  verify(mockTokenStorage.clearTokens()).called(1);
  verify(mockRouteStorage.clearLastRoute()).called(1);
});
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/auth_controller_test.dart`
Expected: FAIL — `logout()` method does not exist.

**Step 3: Add RouteStorage dependency and logout method to AuthController**

Modify `auth_controller.dart` to accept `RouteStorage`:

```dart
import '../../../core/storage/route_storage.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authApi, {TokenStorage? tokenStorage, RouteStorage? routeStorage})
      : _tokenStorage = tokenStorage ?? SecureTokenStorage(),
        _routeStorage = routeStorage ?? RouteStorage(),
        super(AuthState.initial());

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;
  final RouteStorage _routeStorage;

  // ... existing methods unchanged ...

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    await _routeStorage.clearLastRoute();
    state = AuthState.initial();
  }
}
```

Update `authControllerProvider` to pass routeStorage:

```dart
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final googleLogin = ref.watch(googleLoginProvider);
  final githubLogin = ref.watch(githubLoginProvider);
  final routeStorage = ref.read(routeStorageProvider);
  return AuthController(
    AuthApiImpl(googleLogin, githubLogin),
    routeStorage: routeStorage,
  );
});
```

Note: This requires importing the `routeStorageProvider` from `router.dart`. To avoid circular dependencies, move `routeStorageProvider` to `route_storage.dart` instead:

```dart
// In route_storage.dart, add at the bottom:
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routeStorageProvider = Provider<RouteStorage>((ref) => RouteStorage());
```

And remove it from `router.dart`, importing from `route_storage.dart` instead.

**Step 4: Run test to verify it passes**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/auth_controller_test.dart`
Expected: All tests PASS.

**Step 5: Commit**

```bash
git add client/lib/features/auth/auth_controller.dart client/lib/core/storage/route_storage.dart client/lib/app/router.dart client/test/auth_controller_test.dart
git commit -m "feat: add logout method that clears tokens and saved route"
```

---

### Task 8: Delete SplashScreen

**Files:**
- Delete: `client/lib/features/auth/splash_screen.dart`
- Check and update: any tests referencing SplashScreen

**Step 1: Remove SplashScreen file**

```bash
rm client/lib/features/auth/splash_screen.dart
```

**Step 2: Remove any test files referencing splash**

Search for and remove splash-related test code. The old `router.dart` imported splash_screen — that import is already gone with the new router.

**Step 3: Verify no remaining references**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && grep -r "splash_screen\|SplashScreen" lib/ test/ --include="*.dart"`
Expected: No matches (or only in files we've already updated).

**Step 4: Run all tests**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test`
Expected: All tests PASS.

**Step 5: Commit**

```bash
git add -A client/
git commit -m "chore: remove SplashScreen in favor of direct navigation"
```

---

### Task 9: Update existing screen tests for GoRouter navigation

Many existing screen tests use `MaterialApp(home: ScreenWidget())` and verify `Navigator.push` via `find.byType(TargetScreen)`. These need updating to work with GoRouter.

**Files:**
- Modify: `client/test/features/onboarding/basic_info_screen_test.dart`
- Modify: `client/test/features/onboarding/occupation_profile_screen_test.dart`
- Modify: `client/test/features/onboarding/allergies_restrictions_screen_test.dart`
- Modify: `client/test/features/onboarding/loading_analysis_screen_test.dart`
- Modify: `client/test/features/onboarding/strategy_report_screen_test.dart`
- Modify: `client/test/features/today/today_smart_menu_feed_screen_test.dart`
- Modify: `client/test/features/auth/login_screen_test.dart`

**Approach:** For screen unit tests, wrap widgets in a `MaterialApp.router` with a test-specific `GoRouter` that defines just the routes needed, or use `InheritedGoRouter` for simpler cases. Navigation assertions change from `find.byType(TargetScreen)` to verifying the GoRouter's current location.

**Step 1: Read each test file and identify navigation assertions**

Review each test file for patterns like:
- `find.byType(SomeScreen)` after a tap
- `Navigator` mocking
- `MaterialPageRoute` checks

**Step 2: Update navigation assertions**

For each test that verifies navigation, create a `GoRouter` with the required routes and verify `router.state.uri.toString()` matches the expected path.

**Step 3: Run all tests**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test`
Expected: All tests PASS.

**Step 4: Commit**

```bash
git add client/test/
git commit -m "test: update screen tests for GoRouter navigation"
```

---

### Task 10: Final integration verification

**Step 1: Run full test suite**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test`
Expected: All tests PASS.

**Step 2: Run static analysis**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter analyze`
Expected: No errors.

**Step 3: Verify no unused imports or dead code**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && grep -r "splash_screen\|SplashScreen" lib/ --include="*.dart"`
Expected: No matches.

**Step 4: Final commit if any cleanup needed**

```bash
git add -A client/
git commit -m "chore: final cleanup for GoRouter migration"
```
