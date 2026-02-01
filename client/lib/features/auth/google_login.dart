import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/api_config.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

class GoogleLogin implements AuthApi {
  GoogleLogin({
    GoogleSignIn? googleSignIn,
    http.Client? httpClient,
    FlutterSecureStorage? storage,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _httpClient = httpClient ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final GoogleSignIn _googleSignIn;
  final http.Client _httpClient;
  final FlutterSecureStorage _storage;

  @override
  Future<AuthState> loginWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return AuthState.initial();
    }
    final auth = await account.authentication;
    final code = auth.serverAuthCode;
    if (code == null || code.isEmpty) {
      return AuthState.initial();
    }

    final response = await _httpClient.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode != 200) {
      return AuthState.initial();
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = body['accessToken'] as String?;
    final refreshToken = body['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) {
      return AuthState.initial();
    }

    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);

    return AuthState(
      isLoggedIn: true,
      onboardingStep: 1,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}

final googleLoginProvider = Provider<AuthApi>((ref) => GoogleLogin());
