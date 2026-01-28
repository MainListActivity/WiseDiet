import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../services/onboarding_service.dart';
import 'strategy_report_screen.dart';
import '../../../core/theme/app_theme.dart';

class LoadingAnalysisScreen extends ConsumerStatefulWidget {
  const LoadingAnalysisScreen({super.key});

  @override
  ConsumerState<LoadingAnalysisScreen> createState() => _LoadingAnalysisScreenState();
}

class _LoadingAnalysisScreenState extends ConsumerState<LoadingAnalysisScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _service = OnboardingService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _processData();
  }

  Future<void> _processData() async {
    try {
      final profile = ref.read(onboardingProvider);

      // Submit profile
      await _service.submitProfile(profile);

      // Get strategy (simulate some delay for effect)
      await Future.delayed(const Duration(seconds: 2));
      final strategy = await _service.getStrategy();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StrategyReportScreen(strategy: strategy),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: const Icon(Icons.psychology, size: 80, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI Analyzing metabolic needs...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generating your personalized plan',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
