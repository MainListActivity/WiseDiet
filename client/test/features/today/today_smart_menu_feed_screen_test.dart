import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/today/screens/today_smart_menu_feed_screen.dart';

void main() {
  testWidgets('confirm button enabled only after selecting required dishes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TodaySmartMenuFeedScreen(requiredSelections: 2)),
    );

    final confirmButton = find.byKey(const Key('confirm-menu-button'));
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);

    await tester.tap(find.byKey(const Key('dish-checkbox-0')));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);

    await tester.tap(find.byKey(const Key('dish-checkbox-1')));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNotNull);
  });
}
