import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wise_diet/core/network/api_client.dart';

class _FakeAccessTokenProvider implements AccessTokenProvider {
  _FakeAccessTokenProvider(this._token);

  final String? _token;

  @override
  Future<String?> readAccessToken() async => _token;
}

void main() {
  test('should inject bearer token automatically when token exists', () async {
    Map<String, String>? capturedHeaders;
    final inner = MockClient((request) async {
      capturedHeaders = request.headers;
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    final client = ApiClient(
      onUnauthorized: () async {},
      onOnboardingRequired: () async {},
      accessTokenProvider: _FakeAccessTokenProvider('token-abc'),
      httpClient: inner,
    );

    await client.get(Uri.parse('https://example.com/api/onboarding/strategy'));

    expect(capturedHeaders?['authorization'], 'Bearer token-abc');
  });

  test('should trigger unauthorized handler on 401 response', () async {
    var unauthorizedCalled = false;
    final inner = MockClient((request) async {
      return http.Response('', 401);
    });

    final client = ApiClient(
      onUnauthorized: () async {
        unauthorizedCalled = true;
      },
      onOnboardingRequired: () async {},
      accessTokenProvider: _FakeAccessTokenProvider('token-abc'),
      httpClient: inner,
    );

    await client.get(Uri.parse('https://example.com/api/protected'));

    expect(unauthorizedCalled, isTrue);
  });
}
