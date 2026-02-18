import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/history/screens/history_placeholder_screen.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

void main() {
  testWidgets('renders history placeholder with profile card and body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HistoryPlaceholderScreen(
          onProfileTap: () {},
        ),
      ),
    );

    // Profile card
    expect(find.byKey(const Key('profile-card')), findsOneWidget);
    expect(find.text('View profile'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);

    // Placeholder body
    expect(find.text('Your meal history and insights are coming soon.'), findsOneWidget);
  });

  testWidgets('tapping profile card calls onProfileTap', (tester) async {
    var profileTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HistoryPlaceholderScreen(
          onProfileTap: () => profileTapped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('profile-card')));
    await tester.pumpAndSettle();

    expect(profileTapped, isTrue);
  });
}
