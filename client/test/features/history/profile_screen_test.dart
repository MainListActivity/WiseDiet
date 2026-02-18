import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/auth/auth_controller.dart';
import 'package:wise_diet/features/auth/auth_state.dart';
import 'package:wise_diet/features/history/providers/profile_provider.dart';
import 'package:wise_diet/features/history/screens/profile_screen.dart';
import 'package:wise_diet/features/onboarding/models/user_profile.dart';
import 'package:wise_diet/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---- Auth fakes ----

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

// ---- Profile fake notifier ----

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._value);
  final AsyncValue<UserProfile> _value;

  @override
  Future<UserProfile> build() async {
    if (_value is AsyncData<UserProfile>) {
      return (_value as AsyncData<UserProfile>).value;
    }
    if (_value is AsyncError) throw (_value as AsyncError).error;
    await Future.delayed(const Duration(seconds: 60));
    throw UnimplementedError();
  }
}

// ---- Test profile data ----

final _testProfile = UserProfile(
  gender: 'Male',
  age: 28,
  height: 175.0,
  weight: 70.0,
  occupationTags: {1, 2},
  familyMembers: 3,
  allergenTagIds: {3},
  dietaryPreferenceTagIds: {4},
  customAvoidedIngredients: ['香菜'],
);

// ---- Helper builders ----

Widget buildProfileScreen(AsyncValue<UserProfile> profileValue) {
  return ProviderScope(
    overrides: [
      profileProvider.overrideWith(() => _FakeProfileNotifier(profileValue)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProfileScreen(),
    ),
  );
}

Widget buildProfileScreenWithAuth({
  required AsyncValue<UserProfile> profileValue,
  required AuthController Function() authControllerFactory,
}) {
  return ProviderScope(
    overrides: [
      profileProvider.overrideWith(() => _FakeProfileNotifier(profileValue)),
      authControllerProvider.overrideWith(
        (ref) => authControllerFactory(),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProfileScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---- Legacy auth tests (updated for new ProfileScreen) ----

  testWidgets('renders profile screen with avatar and logout button',
      (tester) async {
    await tester.pumpWidget(
      buildProfileScreenWithAuth(
        profileValue: const AsyncValue.loading(),
        authControllerFactory: () =>
            AuthController(FakeAuthApi(), tokenStorage: FakeTokenStorage()),
      ),
    );
    await tester.pump();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const Key('logout-button')), findsOneWidget);
  });

  testWidgets('tapping logout shows confirmation dialog', (tester) async {
    await tester.pumpWidget(
      buildProfileScreenWithAuth(
        profileValue: AsyncValue.data(_testProfile),
        authControllerFactory: () =>
            AuthController(FakeAuthApi(), tokenStorage: FakeTokenStorage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('logout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);
    expect(find.text('You will need to sign in again.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('confirming logout calls AuthController.logout', (tester) async {
    final tokenStorage = FakeTokenStorage();
    await tester.pumpWidget(
      buildProfileScreenWithAuth(
        profileValue: AsyncValue.data(_testProfile),
        authControllerFactory: () {
          final controller =
              AuthController(FakeAuthApi(), tokenStorage: tokenStorage);
          controller.state = const AuthState(
            isLoggedIn: true,
            onboardingStep: 0,
            accessToken: 'token',
            refreshToken: 'refresh',
          );
          return controller;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('logout-button')));
    await tester.pumpAndSettle();

    // Tap the confirm action in the dialog
    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(tokenStorage.cleared, isTrue);
  });

  // ---- New profile section tests ----

  testWidgets('shows loading indicator while profile is loading',
      (tester) async {
    await tester
        .pumpWidget(buildProfileScreen(const AsyncValue.loading()));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows four section cards when profile is loaded',
      (tester) async {
    await tester
        .pumpWidget(buildProfileScreen(AsyncValue.data(_testProfile)));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('profile-section-basic-info')), findsOneWidget);
    expect(
        find.byKey(const Key('profile-section-household')), findsOneWidget);
    expect(
        find.byKey(const Key('profile-section-occupation')), findsOneWidget);
    expect(find.byKey(const Key('profile-section-diet')), findsOneWidget);
  });

  testWidgets('shows gender, age, height, weight values', (tester) async {
    await tester
        .pumpWidget(buildProfileScreen(AsyncValue.data(_testProfile)));
    await tester.pumpAndSettle();
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('175.0'), findsOneWidget);
    expect(find.text('70.0'), findsOneWidget);
  });

  testWidgets('tapping weight edit button shows inline TextField',
      (tester) async {
    await tester
        .pumpWidget(buildProfileScreen(AsyncValue.data(_testProfile)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-edit-weight')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-input-weight')), findsOneWidget);
    expect(find.byKey(const Key('profile-confirm-weight')), findsOneWidget);
    expect(find.byKey(const Key('profile-cancel-weight')), findsOneWidget);
  });

  testWidgets('tapping cancel after edit restores read-only view',
      (tester) async {
    await tester
        .pumpWidget(buildProfileScreen(AsyncValue.data(_testProfile)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-edit-weight')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-cancel-weight')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-input-weight')), findsNothing);
    expect(find.byKey(const Key('profile-edit-weight')), findsOneWidget);
  });

  testWidgets('occupation section shows edit button', (tester) async {
    await tester
        .pumpWidget(buildProfileScreen(AsyncValue.data(_testProfile)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-edit-occupation')), findsOneWidget);
  });

  testWidgets('shows logout button', (tester) async {
    await tester
        .pumpWidget(buildProfileScreen(AsyncValue.data(_testProfile)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('logout-button')), findsOneWidget);
  });

  testWidgets('tapping occupation edit opens bottom sheet', (tester) async {
    await tester
        .pumpWidget(buildProfileScreen(AsyncValue.data(_testProfile)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-edit-occupation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-tag-bottom-sheet')), findsOneWidget);
  });
}
