import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wise_diet/features/onboarding/models/allergen_tag.dart';
import 'package:wise_diet/features/onboarding/models/dietary_preference_tag.dart';
import 'package:wise_diet/features/onboarding/providers/tag_provider.dart';
import 'package:wise_diet/features/onboarding/screens/allergies_restrictions_screen.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

final _mockAllergenTags = [
  AllergenTag(id: 1, label: 'Peanuts', emoji: '🥜', description: 'Tree nuts included', category: 'nuts'),
  AllergenTag(id: 2, label: 'Dairy', emoji: '🥛', description: 'Milk, cheese, butter', category: 'dairy'),
  AllergenTag(id: 3, label: 'Shellfish', emoji: '🦐', description: 'Shrimp, crab, lobster', category: 'seafood'),
  AllergenTag(id: 4, label: 'Eggs', emoji: '🥚', description: 'All forms', category: 'eggs'),
  AllergenTag(id: 5, label: 'Gluten', emoji: '🌾', description: 'Wheat, barley, rye', category: 'grains'),
  AllergenTag(id: 6, label: 'Soy', emoji: '🫘', description: 'Soy sauce, tofu', category: 'legumes'),
];

final _mockDietaryPreferenceTags = [
  DietaryPreferenceTag(id: 1, label: 'Vegetarian', emoji: '🌿'),
  DietaryPreferenceTag(id: 2, label: 'Vegan', emoji: '🌱'),
  DietaryPreferenceTag(id: 3, label: 'Halal', emoji: '🕌'),
  DietaryPreferenceTag(id: 4, label: 'Kosher', emoji: '✡️'),
  DietaryPreferenceTag(id: 5, label: 'Keto', emoji: '🔥'),
  DietaryPreferenceTag(id: 6, label: 'Paleo', emoji: '🥩'),
];

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/onboarding/allergies',
    routes: [
      GoRoute(
        path: '/onboarding/allergies',
        builder: (context, state) => const AllergiesRestrictionsScreen(),
      ),
      GoRoute(
        path: '/onboarding/family',
        builder: (context, state) =>
            const Scaffold(body: Text('How many people are eating?')),
      ),
    ],
  );
}

Widget _buildTestWidget({Brightness brightness = Brightness.light, GoRouter? router}) {
  return ProviderScope(
    overrides: [
      allergenTagsProvider.overrideWith((_) async => _mockAllergenTags),
      dietaryPreferenceTagsProvider.overrideWith((_) async => _mockDietaryPreferenceTags),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: brightness == Brightness.light
          ? ThemeData.light()
          : ThemeData.dark(),
      routerConfig: router ?? _buildTestRouter(),
    ),
  );
}

void main() {
  group('AllergiesRestrictionsScreen', () {
    testWidgets('displays safety warning banner', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('WARNING'), findsOneWidget);
    });

    testWidgets('displays all 6 allergen tags', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Peanuts'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Shellfish'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Gluten'), findsOneWidget);
      expect(find.text('Soy'), findsOneWidget);
    });

    testWidgets('displays all 6 dietary preference tags', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Vegetarian'), findsOneWidget);
      expect(find.text('Vegan'), findsOneWidget);
      expect(find.text('Halal'), findsOneWidget);
      expect(find.text('Kosher'), findsOneWidget);
      expect(find.text('Keto'), findsOneWidget);
      expect(find.text('Paleo'), findsOneWidget);
    });

    testWidgets('tapping allergen card toggles selection', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Initially no check icon for Peanuts
      expect(find.byIcon(Icons.check_circle), findsNothing);

      await tester.tap(find.text('Peanuts'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping dietary preference pill toggles selection', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);

      await tester.tap(find.text('Vegetarian'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('can add and remove custom avoided ingredient', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to make the text field visible
      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Enter text and tap add
      await tester.enterText(find.byType(TextField), 'Cilantro');
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();

      expect(find.text('Cilantro'), findsOneWidget);

      // Remove the chip by tapping close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Cilantro'), findsNothing);
    });

    testWidgets('tapping Skip for now navigates to FamilyParamsScreen', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildTestRouter();
      await tester.pumpWidget(_buildTestWidget(router: router));
      await tester.pumpAndSettle();

      // Scroll down to make Skip button visible
      await tester.scrollUntilVisible(
        find.text('Skip for now'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/onboarding/family',
      );
    });

    testWidgets('Step 3/4 progress indicator is shown', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to make progress indicator visible
      await tester.scrollUntilVisible(
        find.text('Step 3/4'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 3/4'), findsOneWidget);
    });
  });
}
