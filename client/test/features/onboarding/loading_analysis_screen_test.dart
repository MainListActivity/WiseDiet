import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/onboarding/screens/loading_analysis_screen.dart';

void main() {
  testWidgets('renders data vortex loading experience elements', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoadingAnalysisScreen(autoProcess: false),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('data-vortex-rings')), findsOneWidget);
    expect(find.text('Muscle Gain'), findsOneWidget);
    expect(find.text('Vegan'), findsOneWidget);
    expect(find.byKey(const Key('analysis-progress-percent')), findsOneWidget);
    expect(find.text('POWERED BY WISEDIET AI'), findsOneWidget);
  });
}
