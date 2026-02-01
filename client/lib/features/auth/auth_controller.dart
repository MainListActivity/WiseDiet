import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'google_login.dart';
import 'github_login.dart';

abstract class AuthApi {
  Future<AuthState> loginWithGoogle();
  Future<AuthState> loginWithGithub();
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authApi) : super(AuthState.initial());

  final AuthApi _authApi;

  Future<void> loginWithGoogle() async {
    final nextState = await _authApi.loginWithGoogle();
    state = nextState;
  }

  Future<void> loginWithGithub() async {
    final nextState = await _authApi.loginWithGithub();
    state = nextState;
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
  return AuthController(AuthApiImpl(googleLogin, githubLogin));
});
