import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wise_diet/features/onboarding/models/occupation_tag.dart';
import 'package:wise_diet/features/onboarding/providers/tag_provider.dart';
import 'package:wise_diet/features/onboarding/screens/basic_info_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should complete onboarding basic flow', (WidgetTester tester) async {
    // Given: 基础信息页面与可用标签
    final overrideTags = [
      OccupationTag(id: 1, label: 'Programmer (Sedentary)', icon: 'terminal', category: 'Occupation'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          occupationTagsProvider.overrideWith((ref) async => overrideTags),
        ],
        child: const MaterialApp(home: BasicInfoScreen()),
      ),
    );

    // When: 填写基础信息并进入职业标签页
    await tester.enterText(find.bySemanticsLabel('Age'), '30');
    await tester.enterText(find.bySemanticsLabel('Height (cm)'), '180');
    await tester.enterText(find.bySemanticsLabel('Weight (kg)'), '70');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Then: 展示职业标签并可进入家庭参数页
    expect(find.text('Profile Setup'), findsOneWidget);
    await tester.tap(find.text('Programmer (Sedentary)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();

    expect(find.text('Family Parameters'), findsOneWidget);
  });
}
