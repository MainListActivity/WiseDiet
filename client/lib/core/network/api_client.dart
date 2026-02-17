import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

typedef ResponseHook = Future<void> Function();

abstract class AccessTokenProvider {
  Future<String?> readAccessToken();
}

class SecureAccessTokenProvider implements AccessTokenProvider {
  SecureAccessTokenProvider({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: 'accessToken');
}

class ApiClient extends http.BaseClient {
  ApiClient({
    ResponseHook? onUnauthorized,
    ResponseHook? onOnboardingRequired,
    AccessTokenProvider? accessTokenProvider,
    http.Client? httpClient,
  }) : _onUnauthorized = onUnauthorized ?? _noop,
       _onOnboardingRequired = onOnboardingRequired ?? _noop,
       _accessTokenProvider =
           accessTokenProvider ?? SecureAccessTokenProvider(),
       _inner = httpClient ?? http.Client();

  final ResponseHook _onUnauthorized;
  final ResponseHook _onOnboardingRequired;
  final AccessTokenProvider _accessTokenProvider;
  final http.Client _inner;

  static Future<void> _noop() async {}

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _accessTokenProvider.readAccessToken();
    if (token != null &&
        token.isNotEmpty &&
        !request.headers.containsKey('Authorization')) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await _inner.send(request);

    if (response.statusCode == 401) {
      await _onUnauthorized();
    } else if (response.statusCode == 403 &&
        response.headers['x-error-code'] == 'ONBOARDING_REQUIRED') {
      await _onOnboardingRequired();
    }

    return response;
  }

  @override
  void close() {
    _inner.close();
  }
}
