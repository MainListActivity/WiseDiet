import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/widgets/hello_widget.dart';

/// Hello World Widget测试
/// 验证Widget测试框架配置正确
void main() {
  testWidgets('should display Hello World text when widget is rendered', (
    WidgetTester tester,
  ) async {
    // Given: HelloWidget准备渲染
    const widget = HelloWidget();

    // When: 渲染Widget
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: widget)));

    // Then: 验证"Hello, World!"文本显示
    expect(find.text('Hello, World!'), findsOneWidget);
  });

  testWidgets('should display text in center', (WidgetTester tester) async {
    // Given: HelloWidget准备渲染
    const widget = HelloWidget();

    // When: 渲染Widget
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: widget)));

    // Then: 验证Center widget存在
    expect(find.byType(Center), findsOneWidget);
  });
}
