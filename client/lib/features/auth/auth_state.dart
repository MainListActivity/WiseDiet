import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({
    required this.isLoggedIn,
    required this.onboardingStep,
    this.accessToken,
    this.refreshToken,
  });

  final bool isLoggedIn;
  final int onboardingStep;
  final String? accessToken;
  final String? refreshToken;

  factory AuthState.initial() {
    return const AuthState(
      isLoggedIn: false,
      onboardingStep: 0,
      accessToken: null,
      refreshToken: null,
    );
  }
}

final authStateProvider = StateProvider<AuthState>((ref) => AuthState.initial());
