import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wise_diet/features/onboarding/models/occupation_tag.dart';
import 'package:wise_diet/features/onboarding/providers/tag_provider.dart';
import 'package:wise_diet/features/onboarding/screens/basic_info_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should complete onboarding flow without separate family page', (
    WidgetTester tester,
  ) async {
    final overrideTags = [
      OccupationTag(
        id: 1,
        label: 'Programmer (Sedentary)',
        icon: 'terminal',
        category: 'Occupation',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          occupationTagsProvider.overrideWith((ref) async => overrideTags),
        ],
        child: const MaterialApp(home: BasicInfoScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('gender_male_button')));
    await tester.pumpAndSettle();

    final ageSlider = tester.widget<Slider>(
      find.byKey(const Key('age_slider')),
    );
    ageSlider.onChanged?.call(30);
    await tester.pumpAndSettle();

    final heightSlider = tester.widget<Slider>(
      find.byKey(const Key('height_slider')),
    );
    heightSlider.onChanged?.call(180);
    await tester.pumpAndSettle();

    final weightSlider = tester.widget<Slider>(
      find.byKey(const Key('weight_slider')),
    );
    weightSlider.onChanged?.call(70);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('basic_info_next_button')));
    await tester.pumpAndSettle();

    expect(find.text('AI ANALYZING METABOLIC NEEDS...'), findsOneWidget);
    await tester.tap(find.text('Programmer (Sedentary)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();

    expect(find.text('Family Parameters'), findsNothing);
  });
}
