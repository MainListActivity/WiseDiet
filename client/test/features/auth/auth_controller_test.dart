import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/auth/auth_controller.dart';
import 'package:wise_diet/features/auth/auth_state.dart';

class _FakeAuthApi implements AuthApi {
  @override
  Future<AuthState> loginWithGoogle() async =>
      const AuthState(isLoggedIn: true, onboardingStep: 1, accessToken: 'tok', refreshToken: 'ref');

  @override
  Future<AuthState> loginWithGithub() async =>
      const AuthState(isLoggedIn: true, onboardingStep: 1, accessToken: 'tok', refreshToken: 'ref');
}

void main() {
  group('AuthController.completeOnboarding', () {
    test('sets onboardingStep to 0 and preserves tokens', () {
      final controller = AuthController(_FakeAuthApi());
      controller.state = const AuthState(
        isLoggedIn: true,
        onboardingStep: 1,
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      );

      controller.completeOnboarding();

      expect(controller.state.onboardingStep, equals(0));
      expect(controller.state.isLoggedIn, isTrue);
      expect(controller.state.accessToken, equals('access-token'));
      expect(controller.state.refreshToken, equals('refresh-token'));
    });
  });
}
