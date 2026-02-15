import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/today/screens/today_smart_menu_feed_screen.dart';

void main() {
  testWidgets('renders timeline sections with guide and daily insight card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TodaySmartMenuFeedScreen(requiredSelections: 2)),
    );

    expect(find.text('N+1 Selection Guide'), findsOneWidget);
    expect(find.byKey(const Key('daily-insight-card')), findsOneWidget);
    expect(find.byKey(const Key('timeline-breakfast')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lunch'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Lunch'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Snack'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Snack'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Dinner'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Dinner'), findsOneWidget);
  });

  testWidgets('floating progress and confirm state follow dish selections', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TodaySmartMenuFeedScreen(requiredSelections: 2)),
    );

    final confirmButton = find.byKey(const Key('confirm-menu-button'));
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);
    expect(find.byKey(const Key('floating-progress-bar')), findsOneWidget);
    expect(find.text('0 / 2 selected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dish-card-0')));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);
    expect(find.text('1 / 2 selected'), findsOneWidget);
    expect(find.byKey(const Key('dish-selected-0')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('dish-card-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dish-card-1')));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNotNull);
    expect(find.text('2 / 2 selected'), findsOneWidget);
  });
}
