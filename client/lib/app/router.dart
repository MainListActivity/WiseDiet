import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/onboarding/screens/basic_info_screen.dart';

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (!authState.isLoggedIn) {
      return const LoginScreen();
    }
    if (authState.onboardingStep > 0) {
      return const BasicInfoScreen();
    }
    return const Scaffold(body: Center(child: Text('Welcome back')));
  }
}
