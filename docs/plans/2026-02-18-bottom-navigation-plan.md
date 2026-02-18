# Bottom Navigation Framework Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a 3-tab bottom navigation bar (Today / Shopping / History) using GoRouter's StatefulShellRoute, with placeholder screens for Shopping and History, a profile card on the History tab, and a Profile screen with logout.

**Architecture:** Use `StatefulShellRoute.indexedStack` to wrap 3 branches under a shared `MainShell` scaffold with `NavigationBar`. Each branch has its own `GoRoute`. The History branch has a sub-route for the Profile screen. Login/onboarding routes remain outside the shell.

**Tech Stack:** Flutter, GoRouter (StatefulShellRoute), flutter_riverpod, flutter_localizations (ARB)

---

### Task 1: Add i18n keys for navigation and new screens

**Files:**
- Modify: `client/lib/l10n/app_en.arb:167` (before closing brace)
- Modify: `client/lib/l10n/app_zh.arb:118` (before closing brace)

**Step 1: Add English i18n keys**

Add before the closing `}` in `app_en.arb`:

```json
  "navToday": "Today",
  "navShopping": "Shopping",
  "navHistory": "History",
  "shoppingPlaceholderTitle": "Shopping List",
  "shoppingPlaceholderBody": "Your smart shopping list is coming soon.",
  "historyPlaceholderTitle": "History & Me",
  "historyPlaceholderBody": "Your meal history and insights are coming soon.",
  "profileCardViewProfile": "View profile",
  "profileTitle": "Profile",
  "profileLogout": "Log out",
  "profileLogoutConfirmTitle": "Log out?",
  "profileLogoutConfirmBody": "You will need to sign in again.",
  "profileLogoutConfirmCancel": "Cancel",
  "profileLogoutConfirmAction": "Log out"
```

**Step 2: Add Chinese i18n keys**

Add before the closing `}` in `app_zh.arb`:

```json
  "navToday": "今日",
  "navShopping": "采购",
  "navHistory": "档案",
  "shoppingPlaceholderTitle": "采购清单",
  "shoppingPlaceholderBody": "智能采购清单即将推出。",
  "historyPlaceholderTitle": "档案与历史",
  "historyPlaceholderBody": "你的饮食历史和洞察即将推出。",
  "profileCardViewProfile": "查看个人信息",
  "profileTitle": "个人信息",
  "profileLogout": "退出登录",
  "profileLogoutConfirmTitle": "确认退出？",
  "profileLogoutConfirmBody": "退出后需要重新登录。",
  "profileLogoutConfirmCancel": "取消",
  "profileLogoutConfirmAction": "退出登录"
```

**Step 3: Run code generation**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter gen-l10n`
Expected: Generated files updated with new keys.

**Step 4: Commit**

```bash
git add client/lib/l10n/
git commit -m "feat: add i18n keys for bottom navigation, placeholders, and profile"
```

---

### Task 2: Create MainShell widget with bottom NavigationBar

**Files:**
- Test: `client/test/app/main_shell_test.dart`
- Create: `client/lib/app/main_shell.dart`

**Step 1: Write the failing test**

Create `client/test/app/main_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wise_diet/app/main_shell.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

void main() {
  // Helper: build a GoRouter with StatefulShellRoute that uses MainShell
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) =>
                    const Text('today-page', key: Key('today-page')),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/shopping',
                builder: (context, state) =>
                    const Text('shopping-page', key: Key('shopping-page')),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) =>
                    const Text('history-page', key: Key('history-page')),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  testWidgets('renders 3 navigation bar items', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('shows today page by default', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('today-page')), findsOneWidget);
  });

  testWidgets('tapping Shopping tab switches to shopping page', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shopping-page')), findsOneWidget);
  });

  testWidgets('tapping History tab switches to history page', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-page')), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/app/main_shell_test.dart`
Expected: FAIL — `main_shell.dart` does not exist.

**Step 3: Write minimal implementation**

Create `client/lib/app/main_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_outlined),
            selectedIcon: const Icon(Icons.restaurant_menu),
            label: l10n.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: l10n.navShopping,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navHistory,
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/app/main_shell_test.dart`
Expected: All 4 tests PASS.

**Step 5: Commit**

```bash
git add client/lib/app/main_shell.dart client/test/app/main_shell_test.dart
git commit -m "feat: add MainShell widget with 3-tab bottom navigation bar"
```

---

### Task 3: Create ShoppingPlaceholderScreen

**Files:**
- Test: `client/test/features/shopping/shopping_placeholder_screen_test.dart`
- Create: `client/lib/features/shopping/screens/shopping_placeholder_screen.dart`

**Step 1: Write the failing test**

Create `client/test/features/shopping/shopping_placeholder_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/shopping/screens/shopping_placeholder_screen.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

void main() {
  testWidgets('renders shopping placeholder with title and body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShoppingPlaceholderScreen(),
      ),
    );

    expect(find.text('Shopping List'), findsOneWidget);
    expect(find.text('Your smart shopping list is coming soon.'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/features/shopping/shopping_placeholder_screen_test.dart`
Expected: FAIL — file does not exist.

**Step 3: Write minimal implementation**

Create `client/lib/features/shopping/screens/shopping_placeholder_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class ShoppingPlaceholderScreen extends StatelessWidget {
  const ShoppingPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shoppingPlaceholderTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.shoppingPlaceholderBody,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/features/shopping/shopping_placeholder_screen_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add client/lib/features/shopping/ client/test/features/shopping/
git commit -m "feat: add shopping placeholder screen"
```

---

### Task 4: Create HistoryPlaceholderScreen with ProfileCard

**Files:**
- Test: `client/test/features/history/history_placeholder_screen_test.dart`
- Create: `client/lib/features/history/screens/history_placeholder_screen.dart`
- Create: `client/lib/features/history/widgets/profile_card.dart`

**Step 1: Write the failing test**

Create `client/test/features/history/history_placeholder_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/history/screens/history_placeholder_screen.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

void main() {
  testWidgets('renders history placeholder with profile card and body', (tester) async {
    var profileTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HistoryPlaceholderScreen(
          onProfileTap: () => profileTapped = true,
        ),
      ),
    );

    // Profile card
    expect(find.byKey(const Key('profile-card')), findsOneWidget);
    expect(find.text('View profile'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);

    // Placeholder body
    expect(find.text('Your meal history and insights are coming soon.'), findsOneWidget);
  });

  testWidgets('tapping profile card calls onProfileTap', (tester) async {
    var profileTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HistoryPlaceholderScreen(
          onProfileTap: () => profileTapped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('profile-card')));
    await tester.pumpAndSettle();

    expect(profileTapped, isTrue);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/features/history/history_placeholder_screen_test.dart`
Expected: FAIL — files don't exist.

**Step 3: Write ProfileCard widget**

Create `client/lib/features/history/widgets/profile_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class ProfileCard extends StatelessWidget {
  final VoidCallback? onTap;

  const ProfileCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      key: const Key('profile-card'),
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.profileCardViewProfile,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Write HistoryPlaceholderScreen**

Create `client/lib/features/history/screens/history_placeholder_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../widgets/profile_card.dart';

class HistoryPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const HistoryPlaceholderScreen({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyPlaceholderTitle)),
      body: Column(
        children: [
          ProfileCard(onTap: onProfileTap),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.historyPlaceholderBody,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 5: Run test to verify it passes**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/features/history/history_placeholder_screen_test.dart`
Expected: All 2 tests PASS.

**Step 6: Commit**

```bash
git add client/lib/features/history/ client/test/features/history/
git commit -m "feat: add history placeholder screen with profile card"
```

---

### Task 5: Create ProfileScreen with logout

**Files:**
- Test: `client/test/features/history/profile_screen_test.dart`
- Create: `client/lib/features/history/screens/profile_screen.dart`

**Step 1: Write the failing test**

Create `client/test/features/history/profile_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/auth/auth_controller.dart';
import 'package:wise_diet/features/auth/auth_state.dart';
import 'package:wise_diet/features/history/screens/profile_screen.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

class FakeAuthApi implements AuthApi {
  @override
  Future<AuthState> loginWithGoogle() async => throw UnimplementedError();
  @override
  Future<AuthState> loginWithGithub() async => throw UnimplementedError();
}

class FakeTokenStorage implements TokenStorage {
  bool cleared = false;
  @override
  Future<void> clearTokens() async {
    cleared = true;
  }
}

void main() {
  testWidgets('renders profile screen with avatar and logout button', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => AuthController(FakeAuthApi(), tokenStorage: FakeTokenStorage()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(),
        ),
      ),
    );

    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('tapping logout shows confirmation dialog', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => AuthController(FakeAuthApi(), tokenStorage: FakeTokenStorage()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);
    expect(find.text('You will need to sign in again.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('confirming logout calls AuthController.logout', (tester) async {
    final tokenStorage = FakeTokenStorage();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) {
            final controller = AuthController(FakeAuthApi(), tokenStorage: tokenStorage);
            controller.state = const AuthState(
              isLoggedIn: true,
              onboardingStep: 0,
              accessToken: 'token',
              refreshToken: 'refresh',
            );
            return controller;
          },
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    // Tap the confirm action in the dialog
    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(tokenStorage.cleared, isTrue);
    expect(container.read(authControllerProvider).isLoggedIn, isFalse);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/features/history/profile_screen_test.dart`
Expected: FAIL — `profile_screen.dart` does not exist.

**Step 3: Write minimal implementation**

Create `client/lib/features/history/screens/profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              key: const Key('logout-button'),
              onPressed: () => _showLogoutDialog(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(l10n.profileLogout),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
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

**Step 4: Run test to verify it passes**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/features/history/profile_screen_test.dart`
Expected: All 3 tests PASS.

**Step 5: Commit**

```bash
git add client/lib/features/history/screens/profile_screen.dart client/test/features/history/profile_screen_test.dart
git commit -m "feat: add profile screen with logout confirmation dialog"
```

---

### Task 6: Update GoRouter to use StatefulShellRoute

**Files:**
- Modify: `client/lib/app/router.dart`
- Modify: `client/test/app/router_test.dart`

**Step 1: Write the failing test — verify bottom nav renders on /home**

Add a new test to `client/test/app/router_test.dart`:

```dart
testWidgets('renders bottom navigation bar on /home', (tester) async {
  final container = ProviderContainer(
    overrides: [
      authSessionProvider.overrideWith((ref) => Future.value(true)),
      authControllerProvider.overrideWith(
        (ref) {
          final controller = AuthController(FakeAuthApi(),
              tokenStorage: FakeTokenStorage());
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
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byType(NavigationBar), findsOneWidget);
  expect(find.byType(NavigationDestination), findsNWidgets(3));
});
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/app/router_test.dart`
Expected: FAIL — no NavigationBar rendered (current /home route has no shell).

**Step 3: Update router.dart**

Replace the full content of `client/lib/app/router.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/storage/route_storage.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_session_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/history/screens/history_placeholder_screen.dart';
import '../features/history/screens/profile_screen.dart';
import '../features/onboarding/screens/basic_info_screen.dart';
import '../features/onboarding/screens/occupation_profile_screen.dart';
import '../features/onboarding/screens/allergies_restrictions_screen.dart';
import '../features/onboarding/screens/family_params_screen.dart';
import '../features/onboarding/screens/loading_analysis_screen.dart';
import '../features/onboarding/screens/strategy_report_screen.dart';
import '../features/shopping/screens/shopping_placeholder_screen.dart';
import '../features/today/screens/today_smart_menu_feed_screen.dart';
import 'main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final routeStorage = ref.read(routeStorageProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const TodaySmartMenuFeedScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/shopping',
              builder: (context, state) => const ShoppingPlaceholderScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => HistoryPlaceholderScreen(
                onProfileTap: () => GoRouter.of(context).go('/history/profile'),
              ),
              routes: [
                GoRoute(
                  path: 'profile',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
```

**Step 4: Run all router tests to verify they pass**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/app/router_test.dart`
Expected: All 4 tests PASS (3 existing + 1 new).

**Step 5: Commit**

```bash
git add client/lib/app/router.dart client/test/app/router_test.dart
git commit -m "feat: integrate StatefulShellRoute for bottom navigation in GoRouter"
```

---

### Task 7: Remove AppBar from TodaySmartMenuFeedScreen (now provided by MainShell layout)

**Note:** The TodaySmartMenuFeedScreen currently has its own `Scaffold` with `appBar` and `bottomNavigationBar`. Since MainShell now provides the bottom nav, and TodaySmartMenuFeedScreen still needs its own Scaffold for the appBar and floating progress bar, this should continue to work as nested Scaffolds. **No change needed** — Flutter handles nested Scaffolds correctly and the bottom nav from MainShell will appear below TodaySmartMenuFeedScreen's own bottomNavigationBar.

**Skip this task — verify by running existing tests.**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test test/features/today/today_smart_menu_feed_screen_test.dart`
Expected: All existing tests PASS unchanged.

---

### Task 8: Run full test suite and verify

**Step 1: Run all tests**

Run: `cd /Users/y/IdeaProjects/WiseDiet/client && flutter test`
Expected: All tests PASS.

**Step 2: Final commit if any fixes needed**

Only if tests required adjustments.
