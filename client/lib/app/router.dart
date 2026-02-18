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
