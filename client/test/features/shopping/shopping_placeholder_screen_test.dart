import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/shopping/screens/shopping_placeholder_screen.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

void main() {
  testWidgets('renders shopping placeholder with title and body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShoppingPlaceholderScreen(),
      ),
    );

    expect(find.text('Shopping List'), findsOneWidget);
    expect(find.text('Your smart shopping list is coming soon.'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
  });
}
