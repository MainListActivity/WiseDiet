import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'google_login.dart';

abstract class AuthApi {
  Future<AuthState> loginWithGoogle();
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authApi) : super(AuthState.initial());

  final AuthApi _authApi;

  Future<void> loginWithGoogle() async {
    final nextState = await _authApi.loginWithGoogle();
    state = nextState;
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final googleLogin = ref.watch(googleLoginProvider);
  return AuthController(googleLogin);
});
