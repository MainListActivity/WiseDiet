import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../models/user_profile.dart';

class OnboardingService {
  OnboardingService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> submitProfile(UserProfile profile) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/onboarding/profile'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(profile.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit profile (${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> getStrategy() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/onboarding/strategy'),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load strategy (${response.statusCode})');
    }
  }
}
