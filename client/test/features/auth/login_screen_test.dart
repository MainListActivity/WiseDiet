import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wise_diet/l10n/app_localizations.dart';
import 'package:wise_diet/app/router.dart';
import 'package:wise_diet/core/storage/route_storage.dart';
import 'package:wise_diet/features/auth/auth_controller.dart';
import 'package:wise_diet/features/auth/auth_state.dart';
import 'package:wise_diet/features/auth/auth_session_provider.dart';
import 'package:wise_diet/features/auth/login_screen.dart';

class MockAuthApi implements AuthApi {
  @override
  Future<AuthState> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return const AuthState(
      isLoggedIn: true,
      onboardingStep: 1,
      accessToken: 'test_token',
      refreshToken: 'test_refresh_token',
    );
  }

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

  testWidgets(
    'tapping "Continue with Google" logs in and navigates to next screen',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith((ref) => Future.value(false)),
          authControllerProvider.overrideWith(
            (ref) => AuthController(MockAuthApi(),
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

      // Verify initial state: LoginScreen is visible (redirected from /home to /login)
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // Tap the Google login button
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      await tester.pumpAndSettle();
    },
  );
}
