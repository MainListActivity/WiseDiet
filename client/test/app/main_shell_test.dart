import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wise_diet/app/main_shell.dart';
import 'package:wise_diet/l10n/app_localizations.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) =>
                    const Text('today-page', key: Key('today-page')),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/shopping',
                builder: (context, state) =>
                    const Text('shopping-page', key: Key('shopping-page')),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) =>
                    const Text('history-page', key: Key('history-page')),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  testWidgets('renders 3 navigation bar items', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('shows today page by default', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('today-page')), findsOneWidget);
  });

  testWidgets('tapping Shopping tab switches to shopping page', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shopping-page')), findsOneWidget);
  });

  testWidgets('tapping History tab switches to history page', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-page')), findsOneWidget);
  });
}
