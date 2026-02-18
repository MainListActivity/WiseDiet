import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/auth/auth_controller.dart';
import 'package:wise_diet/features/auth/auth_state.dart';
import 'package:wise_diet/features/history/screens/profile_screen.dart';
import 'package:wise_diet/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
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
