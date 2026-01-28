import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../models/user_profile.dart';

class OnboardingService {
  Future<void> submitProfile(UserProfile profile) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/onboarding/profile'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(profile.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit profile');
    }
  }

  Future<Map<String, dynamic>> getStrategy() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/onboarding/strategy'),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load strategy');
    }
  }
}
