import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/l10n/app_localizations.dart';
import 'package:wise_diet/app/router.dart';
import 'package:wise_diet/features/auth/auth_state.dart';
import 'package:wise_diet/features/auth/google_login.dart';
import 'package:wise_diet/features/auth/login_screen.dart';
import 'package:wise_diet/features/onboarding/screens/basic_info_screen.dart';
import 'package:wise_diet/features/auth/splash_screen.dart';

// Mock GoogleLogin
class MockGoogleLogin extends GoogleLogin {
  MockGoogleLogin() : super();

  @override
  Future<AuthState> loginWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));
    return const AuthState(
      isLoggedIn: true,
      onboardingStep: 1,
      accessToken: 'test_token',
      refreshToken: 'test_refresh_token',
    );
  }
}

void main() {
  testWidgets(
    'tapping "Continue with Google" logs in and navigates to next screen',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [googleLoginProvider.overrideWithValue(MockGoogleLogin())],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppRouter(),
          ),
        ),
      );
      final splash = tester.widget<SplashScreen>(find.byType(SplashScreen));
      splash.onFinished();
      await tester.pumpAndSettle();

      // Verify initial state: LoginScreen is visible
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // Tap the button
      await tester.tap(find.text('Continue with Google'));

      // Pump to process the tap and start the async operation
      await tester.pump();

      // Wait for the async operation (login) and navigation to complete
      await tester.pumpAndSettle();

      // Verify navigation: LoginScreen should be gone, BasicInfoScreen should be visible
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(BasicInfoScreen), findsOneWidget);
    },
  );
}
