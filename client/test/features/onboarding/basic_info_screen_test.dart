import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wise_diet/features/onboarding/providers/onboarding_provider.dart';
import 'package:wise_diet/features/onboarding/screens/basic_info_screen.dart';

void main() {
  testWidgets('renders 03a design widgets and BMI preview', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BasicInfoScreen()),
      ),
    );

    expect(find.text('Profile Setup'), findsOneWidget);
    expect(find.byKey(const Key('onboarding_step_1')), findsOneWidget);
    expect(
      find.text(
        'Tell us a bit about yourself so our AI can calculate your precise nutritional needs.',
      ),
      findsOneWidget,
    );

    expect(find.byKey(const Key('gender_male_button')), findsOneWidget);
    expect(find.byKey(const Key('gender_female_button')), findsOneWidget);
    expect(find.byKey(const Key('gender_other_button')), findsOneWidget);

    expect(find.byKey(const Key('age_slider')), findsOneWidget);
    expect(find.byKey(const Key('height_slider')), findsOneWidget);
    expect(find.byKey(const Key('weight_slider')), findsOneWidget);

    expect(find.text('Estimated BMI'), findsOneWidget);
    expect(find.byKey(const Key('bmi_value_text')), findsOneWidget);

    expect(find.text('Household Diners'), findsOneWidget);
    expect(find.byKey(const Key('household_minus_button')), findsOneWidget);
    expect(find.byKey(const Key('household_plus_button')), findsOneWidget);
    expect(find.byKey(const Key('household_value_text')), findsOneWidget);

    expect(find.byKey(const Key('basic_info_next_button')), findsOneWidget);
  });

  testWidgets('selects values and writes onboarding state before next step', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/onboarding/basic-info',
      routes: [
        GoRoute(
          path: '/onboarding/basic-info',
          builder: (context, state) => const BasicInfoScreen(),
        ),
        GoRoute(
          path: '/onboarding/occupation',
          builder: (context, state) =>
              const Scaffold(body: Text('Occupation')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.byKey(const Key('gender_other_button')));
    await tester.pump();

    final ageSlider = tester.widget<Slider>(
      find.byKey(const Key('age_slider')),
    );
    ageSlider.onChanged?.call(35);
    await tester.pump();

    final heightSlider = tester.widget<Slider>(
      find.byKey(const Key('height_slider')),
    );
    heightSlider.onChanged?.call(182);
    await tester.pump();

    final weightSlider = tester.widget<Slider>(
      find.byKey(const Key('weight_slider')),
    );
    weightSlider.onChanged?.call(74);
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('household_plus_button')));
    await tester.tap(find.byKey(const Key('household_plus_button')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('basic_info_next_button')));
    await tester.tap(find.byKey(const Key('basic_info_next_button')));
    await tester.pumpAndSettle();

    final profile = container.read(onboardingProvider);
    expect(profile.gender, 'Other');
    expect(profile.age, 35);
    expect(profile.height, 182);
    expect(profile.weight, 74);
    expect(profile.familyMembers, 2);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/onboarding/occupation',
    );
  });
}
