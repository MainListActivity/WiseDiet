import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

/// Hello World Widget
/// 简单的测试Widget，用于验证测试框架
class HelloWidget extends StatelessWidget {
  const HelloWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(context.l10n.helloWorld, style: const TextStyle(fontSize: 24)),
    );
  }
}
