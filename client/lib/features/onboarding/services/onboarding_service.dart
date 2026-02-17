import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../models/user_profile.dart';

abstract class AccessTokenProvider {
  Future<String?> readAccessToken();
}

class SecureAccessTokenProvider implements AccessTokenProvider {
  SecureAccessTokenProvider({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: 'accessToken');
  }
}

class OnboardingService {
  OnboardingService({http.Client? client, AccessTokenProvider? accessTokenProvider})
    : _client = client ?? http.Client(),
      _accessTokenProvider = accessTokenProvider ?? SecureAccessTokenProvider();

  final http.Client _client;
  final AccessTokenProvider _accessTokenProvider;

  Future<void> submitProfile(UserProfile profile) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/onboarding/profile'),
      headers: await _headers(),
      body: json.encode(profile.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit profile (${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> getStrategy() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/onboarding/strategy'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load strategy (${response.statusCode})');
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _accessTokenProvider.readAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
