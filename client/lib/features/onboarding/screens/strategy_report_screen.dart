import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StrategyReportScreen extends StatelessWidget {
  final Map<String, dynamic> strategy;

  const StrategyReportScreen({super.key, required this.strategy});

  @override
  Widget build(BuildContext context) {
    final keyPoints = Map<String, String>.from(strategy['key_points'] ?? {});

    return Scaffold(
      appBar: AppBar(title: const Text('Your Strategy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strategy['title'] ?? 'Health Strategy',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Text(
                strategy['summary'] ?? '',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Key Focus Areas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            ...keyPoints.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(entry.value),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Home Dashboard (out of scope for this task)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Welcome to WiseDiet!')),
                  );
                },
                child: const Text('Start My Journey'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
