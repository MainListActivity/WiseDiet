import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/onboarding/screens/basic_info_screen.dart';
import '../l10n/l10n.dart';

class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter> {
  bool _showSplash = true;

  void _onSplashFinished() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen on first launch
    if (_showSplash) {
      return SplashScreen(onFinished: _onSplashFinished);
    }

    final authState = ref.watch(authControllerProvider);
    if (!authState.isLoggedIn) {
      return const LoginScreen();
    }
    if (authState.onboardingStep > 0) {
      return const BasicInfoScreen();
    }
    return Scaffold(body: Center(child: Text(context.l10n.welcomeBack)));
  }
}
