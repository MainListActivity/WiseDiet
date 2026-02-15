import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/onboarding/models/occupation_tag.dart';
import 'package:wise_diet/features/onboarding/providers/tag_provider.dart';
import 'package:wise_diet/features/onboarding/screens/occupation_profile_screen.dart';

final _mockTags = [
  OccupationTag(id: 1, label: 'Programmer (Sedentary)', icon: 'terminal', category: 'Occupation'),
  OccupationTag(id: 2, label: 'Doctor (Shifts)', category: 'Occupation'),
  OccupationTag(id: 3, label: 'Freelancer (Irregular)', category: 'Occupation'),
  OccupationTag(id: 4, label: 'Teacher (Standing)', category: 'Occupation'),
  OccupationTag(id: 5, label: 'Seeking Pregnancy', category: 'Health'),
  OccupationTag(id: 6, label: 'Sugar Control', icon: 'monitor_heart', category: 'Health'),
  OccupationTag(id: 7, label: 'Muscle Gain', category: 'Health'),
  OccupationTag(id: 8, label: 'Frequent Traveler', category: 'Lifestyle'),
  OccupationTag(id: 9, label: 'Post-Op Recovery', category: 'Health'),
];

Widget _buildTestWidget({Brightness brightness = Brightness.light}) {
  return ProviderScope(
    overrides: [
      occupationTagsProvider.overrideWith((_) async => _mockTags),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.light
          ? ThemeData.light()
          : ThemeData.dark(),
      home: const OccupationProfileScreen(),
    ),
  );
}

void main() {
  group('OccupationProfileScreen', () {
    testWidgets('displays all 9 tags matching design spec', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Programmer (Sedentary)'), findsOneWidget);
      expect(find.text('Doctor (Shifts)'), findsOneWidget);
      expect(find.text('Freelancer (Irregular)'), findsOneWidget);
      expect(find.text('Teacher (Standing)'), findsOneWidget);
      expect(find.text('Seeking Pregnancy'), findsOneWidget);
      expect(find.text('Sugar Control'), findsOneWidget);
      expect(find.text('Muscle Gain'), findsOneWidget);
      expect(find.text('Frequent Traveler'), findsOneWidget);
      expect(find.text('Post-Op Recovery'), findsOneWidget);
    });

    testWidgets('tapping Skip for now navigates to FamilyParamsScreen', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(find.text('How many people are eating?'), findsOneWidget);
    });

    testWidgets('unselected tag text uses light color in dark mode', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Doctor (Shifts)'));
      final color = textWidget.style?.color;

      // Dark mode should NOT use grey[700] (too dark to read)
      expect(color, isNot(equals(Colors.grey[700])));
    });
  });
}
