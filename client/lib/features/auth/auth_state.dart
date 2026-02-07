class AuthState {
  const AuthState({
    required this.isLoggedIn,
    required this.onboardingStep,
    this.accessToken,
    this.refreshToken,
    this.message,
  });

  final bool isLoggedIn;
  final int onboardingStep;
  final String? accessToken;
  final String? refreshToken;
  final String? message;

  factory AuthState.initial() {
    return const AuthState(
      isLoggedIn: false,
      onboardingStep: 0,
      accessToken: null,
      refreshToken: null,
      message: null,
    );
  }
}
