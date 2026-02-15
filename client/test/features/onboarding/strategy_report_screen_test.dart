import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/onboarding/screens/strategy_report_screen.dart';

void main() {
  testWidgets('tapping start button navigates to today smart menu page', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StrategyReportScreen(
          strategy: {
            'title': 'Health Strategy',
            'summary': 'Summary',
            'key_points': {'Low GI': 'Avoid sugar spikes'},
          },
        ),
      ),
    );

    await tester.tap(find.text('Start My Journey'));
    await tester.pumpAndSettle();

    expect(find.text("Today's Smart Menu"), findsOneWidget);
  });
}
