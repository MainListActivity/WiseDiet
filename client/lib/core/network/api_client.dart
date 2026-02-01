import 'package:http/http.dart' as http;
import '../../features/auth/auth_controller.dart';

class ApiClient {
  ApiClient(this._authController, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final AuthController _authController;
  final http.Client _httpClient;

  Future<http.Response> get(Uri uri) async {
    final response = await _httpClient.get(uri);
    await _handleResponse(response);
    return response;
  }

  Future<http.Response> post(Uri uri, {Object? body, Map<String, String>? headers}) async {
    final response = await _httpClient.post(uri, body: body, headers: headers);
    await _handleResponse(response);
    return response;
  }

  Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await _authController.handleUnauthorized();
      return;
    }
    if (response.statusCode == 403 && response.headers['x-error-code'] == 'ONBOARDING_REQUIRED') {
      await _authController.handleOnboardingRequired();
    }
  }
}
