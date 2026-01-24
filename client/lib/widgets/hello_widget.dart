import 'package:flutter/material.dart';

/// Hello World Widget
/// 简单的测试Widget，用于验证测试框架
class HelloWidget extends StatelessWidget {
  const HelloWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Hello, World!', style: TextStyle(fontSize: 24)),
    );
  }
}
