import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/core/storage/route_storage.dart';
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

class FakeRouteStorage extends RouteStorage {
  bool cleared = false;

  @override
  Future<String?> getLastRoute() async => null;

  @override
  Future<void> saveLastRoute(String route) async {}

  @override
  Future<void> clearLastRoute() async {
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

  test('logout clears both tokens and last route', () async {
    final tokenStorage = FakeTokenStorage();
    final routeStorage = FakeRouteStorage();
    final controller = AuthController(
      FakeAuthApi(),
      tokenStorage: tokenStorage,
      routeStorage: routeStorage,
    );
    await controller.logout();
    expect(controller.state.isLoggedIn, false);
    expect(tokenStorage.cleared, true);
    expect(routeStorage.cleared, true);
  });

  test('handleUnauthorized does not clear last route', () async {
    final tokenStorage = FakeTokenStorage();
    final routeStorage = FakeRouteStorage();
    final controller = AuthController(
      FakeAuthApi(),
      tokenStorage: tokenStorage,
      routeStorage: routeStorage,
    );
    await controller.handleUnauthorized();
    expect(tokenStorage.cleared, true);
    expect(routeStorage.cleared, false);
  });
}
