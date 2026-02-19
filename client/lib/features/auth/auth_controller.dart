import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/storage/route_storage.dart';
import 'auth_state.dart';
import 'google_login.dart';
import 'github_login.dart';

abstract class AuthApi {
  Future<AuthState> loginWithGoogle();
  Future<AuthState> loginWithGithub();
}

abstract class TokenStorage {
  Future<void> clearTokens();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authApi, {TokenStorage? tokenStorage, RouteStorage? routeStorage})
      : _tokenStorage = tokenStorage ?? SecureTokenStorage(),
        _routeStorage = routeStorage ?? RouteStorage(),
        super(AuthState.initial());

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;
  final RouteStorage _routeStorage;

  Future<void> loginWithGoogle() async {
    final nextState = await _authApi.loginWithGoogle();
    state = nextState;
  }

  Future<void> loginWithGithub() async {
    final nextState = await _authApi.loginWithGithub();
    state = nextState;
  }

  Future<void> handleUnauthorized() async {
    await _tokenStorage.clearTokens();
    state = const AuthState(
      isLoggedIn: false,
      onboardingStep: 0,
      accessToken: null,
      refreshToken: null,
      message: 'accountUnavailable',
    );
  }

  Future<void> handleOnboardingRequired() async {
    state = AuthState(
      isLoggedIn: true,
      onboardingStep: 1,
      accessToken: state.accessToken,
      refreshToken: state.refreshToken,
      message: null,
    );
  }


  void completeOnboarding() {
    state = AuthState(
      isLoggedIn: true,
      onboardingStep: 0,
      accessToken: state.accessToken,
      refreshToken: state.refreshToken,
    );
  }
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    await _routeStorage.clearLastRoute();
    state = AuthState.initial();
  }
}

class AuthApiImpl implements AuthApi {
  AuthApiImpl(this._googleLogin, this._githubLogin);

  final GoogleLogin _googleLogin;
  final GithubLogin _githubLogin;

  @override
  Future<AuthState> loginWithGoogle() {
    return _googleLogin.loginWithGoogle();
  }

  @override
  Future<AuthState> loginWithGithub() {
    return _githubLogin.loginWithGithub();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final googleLogin = ref.watch(googleLoginProvider);
  final githubLogin = ref.watch(githubLoginProvider);
  final routeStorage = ref.read(routeStorageProvider);
  return AuthController(
    AuthApiImpl(googleLogin, githubLogin),
    routeStorage: routeStorage,
  );
});
