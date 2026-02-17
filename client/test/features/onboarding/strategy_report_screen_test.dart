import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wise_diet/features/onboarding/screens/strategy_report_screen.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

void main() {
  const strategyPayload = {
    'title': 'Personalized Health Strategy',
    'summary': 'Summary',
    'key_points': {'Low GI': 'Avoid sugar spikes'},
    'projected_impact': {'focus_boost': '+15%', 'calorie_target': '2050'},
    'preferences': {
      'daily_focus': 'Mental Clarity',
      'meal_frequency': '3 meals + 1 snack',
      'cooking_level': 'Beginner Friendly',
      'budget': '\$20-\$30',
    },
    'info_hint': 'You can change these preferences anytime from your profile.',
    'cta_text': "Generate Today's Plan",
  };

  testWidgets('renders strategy report advanced sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StrategyReportScreen(strategy: strategyPayload),
      ),
    );

    expect(find.text('Projected Impact'), findsOneWidget);
    expect(find.text('Focus Boost'), findsOneWidget);
    expect(find.text('+15%'), findsOneWidget);
    expect(find.text('Calorie Target'), findsOneWidget);
    expect(find.text('2050'), findsOneWidget);

    expect(find.text('Your Preferences'), findsOneWidget);
    expect(find.text('Daily Focus'), findsOneWidget);
    expect(find.text('Meal Frequency'), findsOneWidget);
    expect(find.text('Cooking Level'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Adjust'), findsOneWidget);

    expect(
      find.byKey(const Key('strategy-progress-indicator')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('strategy-info-card')), findsOneWidget);
    expect(find.byKey(const Key('strategy-fixed-cta')), findsOneWidget);
    expect(find.text("Generate Today's Plan"), findsOneWidget);
  });

  testWidgets('allows editing preference values from the report', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StrategyReportScreen(strategy: strategyPayload),
      ),
    );

    await tester.tap(find.byKey(const Key('preference-item-daily_focus')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Energy'));
    await tester.pumpAndSettle();

    expect(find.text('Energy'), findsOneWidget);
  });

  testWidgets('tapping start button navigates to today smart menu page', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/onboarding/strategy',
      routes: [
        GoRoute(
          path: '/onboarding/strategy',
          builder: (context, state) =>
              const StrategyReportScreen(strategy: strategyPayload),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text("Today's Smart Menu")),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    await tester.tap(find.text("Generate Today's Plan"));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/home',
    );
  });
}
