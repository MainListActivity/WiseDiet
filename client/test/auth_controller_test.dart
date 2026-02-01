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

class FakeTokenStorage implements TokenStorage {
  bool cleared = false;

  @override
  Future<void> clearTokens() async {
    cleared = true;
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

  test('handle unauthorized clears tokens and logs out', () async {
    final storage = FakeTokenStorage();
    final controller = AuthController(FakeAuthApi(), tokenStorage: storage);
    await controller.handleUnauthorized();
    expect(controller.state.isLoggedIn, false);
    expect(storage.cleared, true);
  });
}
