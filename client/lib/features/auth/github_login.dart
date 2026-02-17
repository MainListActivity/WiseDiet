import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import 'auth_state.dart';

class GithubLogin {
  GithubLogin({
    AppLinks? appLinks,
    http.Client? httpClient,
    FlutterSecureStorage? storage,
    Future<bool> Function(Uri url)? launcher,
  }) : _appLinks = appLinks ?? AppLinks(),
       _httpClient = httpClient ?? ApiClient(),
       _storage = storage ?? const FlutterSecureStorage(),
       _launcher = launcher ?? launchUrl;

  final AppLinks _appLinks;
  final http.Client _httpClient;
  final FlutterSecureStorage _storage;
  final Future<bool> Function(Uri url) _launcher;

  Future<AuthState> loginWithGithub() async {
    final uriResponse = await _httpClient.get(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/github'),
    );

    if (uriResponse.statusCode != 200) {
      return AuthState.initial();
    }

    final uriBody = jsonDecode(uriResponse.body);
    final authUriString = uriBody['authUri'];
    if (authUriString == null) {
      return AuthState.initial();
    }

    final launched = await _launcher(Uri.parse(authUriString));
    if (!launched) {
      return AuthState.initial();
    }

    final Uri callbackUri = await _appLinks.uriLinkStream.first;
    final code = callbackUri.queryParameters['code'];
    final state = callbackUri.queryParameters['state'];
    if (code == null || code.isEmpty || state == null || state.isEmpty) {
      return AuthState.initial();
    }

    final response = await _httpClient.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/github'),
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

final githubLoginProvider = Provider<GithubLogin>((ref) {
  final client = ref.watch(authApiClientProvider);
  return GithubLogin(httpClient: client);
});
