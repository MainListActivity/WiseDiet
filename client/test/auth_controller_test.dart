import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/auth/auth_controller.dart';
import 'package:wise_diet/features/auth/auth_state.dart';

class FakeAuthApi implements AuthApi {
  @override
  Future<AuthState> loginWithGoogle() async {
    return const AuthState(
      isLoggedIn: true,
      onboardingStep: 1,
      accessToken: 'access',
      refreshToken: 'refresh',
    );
  }

  @override
  Future<AuthState> loginWithGithub() async {
    return const AuthState(
      isLoggedIn: true,
      onboardingStep: 1,
      accessToken: 'access',
      refreshToken: 'refresh',
    );
  }
}

void main() {
  test('login success updates state', () async {
    final controller = AuthController(FakeAuthApi());
    await controller.loginWithGoogle();
    expect(controller.state.isLoggedIn, true);
  });

  test('github login success updates state', () async {
    final controller = AuthController(FakeAuthApi());
    await controller.loginWithGithub();
    expect(controller.state.isLoggedIn, true);
  });
}
