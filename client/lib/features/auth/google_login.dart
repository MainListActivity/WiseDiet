import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import 'auth_state.dart';

class GoogleLogin {
  GoogleLogin({http.Client? httpClient, FlutterSecureStorage? storage})
    : _httpClient = httpClient ?? ApiClient(),
      _storage = storage ?? const FlutterSecureStorage();

  final http.Client _httpClient;
  final FlutterSecureStorage _storage;

  Future<AuthState> loginWithGoogle() async {
    final uriResponse = await _httpClient.get(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/google'),
    );

    if (uriResponse.statusCode != 200) {
      debugPrint(
        '[GoogleLogin] GET /api/auth/google failed: ${uriResponse.statusCode}',
      );
      return AuthState.initial();
    }

    final uriBody = jsonDecode(uriResponse.body);
    final clientId = uriBody['clientId'] as String?;
    final scopes = (uriBody['scopes'] as List<dynamic>?)?.cast<String>();
    final state = uriBody['state'] as String?;
    debugPrint(
      '[GoogleLogin] clientId=$clientId, scopes=$scopes, state=$state',
    );

    if (clientId == null || state == null) {
      debugPrint('[GoogleLogin] clientId or state is null');
      return AuthState.initial();
    }

    final String? code;
    try {
      code = await requestServerAuthCode(
        serverClientId: clientId,
        scopes: scopes ?? [],
      );
    } on PlatformException catch (e) {
      debugPrint('[GoogleLogin] PlatformException: $e');
      return AuthState.initial();
    }
    debugPrint('[GoogleLogin] serverAuthCode=$code');
    if (code == null || code.isEmpty) {
      debugPrint('[GoogleLogin] code is null or empty');
      return AuthState.initial();
    }

    final response = await _httpClient.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code, 'state': state}),
    );

    if (response.statusCode != 200) {
      debugPrint(
        '[GoogleLogin] POST /api/auth/google failed: ${response.statusCode} ${response.body}',
      );
      return AuthState.initial();
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = body['accessToken'] as String?;
    final refreshToken = body['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) {
      debugPrint(
        '[GoogleLogin] tokens are null: accessToken=$accessToken, refreshToken=$refreshToken',
      );
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

  Future<String?> requestServerAuthCode({
    required String serverClientId,
    required List<String> scopes,
  }) async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: serverClientId,
        scopes: scopes,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        return null;
      }
      return account.serverAuthCode;
    } on PlatformException {
      return null;
    }
  }
}

final googleLoginProvider = Provider<GoogleLogin>((ref) {
  final client = ref.watch(authApiClientProvider);
  return GoogleLogin(httpClient: client);
});
