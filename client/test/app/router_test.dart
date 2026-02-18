import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wise_diet/app/router.dart';
import 'package:wise_diet/core/storage/route_storage.dart';
import 'package:wise_diet/features/auth/auth_controller.dart';
import 'package:wise_diet/features/auth/auth_state.dart';
import 'package:wise_diet/features/auth/auth_session_provider.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppRouter redirect', () {
    testWidgets('redirects to /login when not authenticated', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith((ref) => Future.value(false)),
          authControllerProvider.overrideWith(
            (ref) => AuthController(FakeAuthApi(),
                tokenStorage: FakeTokenStorage()),
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

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/login',
      );
    });

    testWidgets('redirects to /home when authenticated and no saved route',
        (tester) async {
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

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/home',
      );
    });

    testWidgets(
        'redirects to /onboarding/basic-info when onboarding required',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith((ref) => Future.value(true)),
          authControllerProvider.overrideWith(
            (ref) {
              final controller = AuthController(FakeAuthApi(),
                  tokenStorage: FakeTokenStorage());
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

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/onboarding/basic-info',
      );
    });

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
  });
}
