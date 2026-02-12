import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wise_diet/features/auth/auth_state.dart';
import 'package:wise_diet/features/auth/google_login.dart';

class ThrowingGoogleLogin extends GoogleLogin {
  ThrowingGoogleLogin({required http.Client httpClient}) : super(httpClient: httpClient);

  @override
  Future<String?> requestServerAuthCode({
    required String serverClientId,
    required List<String> scopes,
  }) async {
    throw PlatformException(code: 'sign_in_failed', message: 'ApiException: 10');
  }
}

void main() {
  test('returns initial state when Google sign-in throws PlatformException', () async {
    final httpClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          '{"clientId":"server-client-id","state":"state-123","scopes":["email"]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      throw UnimplementedError('POST should not be called when sign-in fails.');
    });

    final login = ThrowingGoogleLogin(httpClient: httpClient);

    final state = await login.loginWithGoogle();

    expect(state, AuthState.initial());
  });
}
