import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/api_config.dart';
import 'auth_state.dart';

class GoogleLogin {
  GoogleLogin({http.Client? httpClient, FlutterSecureStorage? storage})
    : _httpClient = httpClient ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  final http.Client _httpClient;
  final FlutterSecureStorage _storage;

  Future<AuthState> loginWithGoogle() async {
    final uriResponse = await _httpClient.get(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/google'),
    );

    if (uriResponse.statusCode != 200) {
      return AuthState.initial();
    }

    final uriBody = jsonDecode(uriResponse.body);
    final clientId = uriBody['clientId'] as String?;
    final scopes = (uriBody['scopes'] as List<dynamic>?)?.cast<String>();
    final state = uriBody['state'] as String?;

    if (clientId == null || state == null) {
      return AuthState.initial();
    }

    final googleSignIn = GoogleSignIn(
      serverClientId: clientId,
      scopes: scopes ?? [],
    );
    final account = await googleSignIn.signIn();
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
      body: jsonEncode({'code': code, 'state': state}),
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

final googleLoginProvider = Provider<GoogleLogin>((ref) => GoogleLogin());
