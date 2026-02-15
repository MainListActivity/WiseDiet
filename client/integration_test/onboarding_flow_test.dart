import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wise_diet/features/onboarding/models/allergen_tag.dart';
import 'package:wise_diet/features/onboarding/models/dietary_preference_tag.dart';
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
          allergenTagsProvider.overrideWith((ref) async => [
            AllergenTag(id: 1, label: 'Peanuts', emoji: '\u{1F95C}', description: 'Tree nuts included', category: 'nuts'),
          ]),
          dietaryPreferenceTagsProvider.overrideWith((ref) async => [
            DietaryPreferenceTag(id: 1, label: 'Vegetarian', emoji: '\u{1F33F}'),
          ]),
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

    // Then: 展示职业标签并可进入过敏页
    expect(find.text('Profile Setup'), findsOneWidget);
    await tester.tap(find.byKey(const Key('basic_info_next_button')));
    await tester.pumpAndSettle();

    await tester.pumpAndSettle();
    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();

    // 验证进入过敏/限制页面
    expect(find.textContaining('WARNING'), findsOneWidget);
    expect(find.text('Peanuts'), findsOneWidget);

    // 跳过过敏页进入家庭参数页
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('How many people are eating?'), findsOneWidget);
  });
}
