import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../onboarding/models/user_profile.dart';

class ProfileService {
  ProfileService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<UserProfile> getProfile() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/profile'),
    );
    if (response.statusCode == 200) {
      return UserProfile.fromJson(
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('Failed to load profile (${response.statusCode})');
  }

  Future<UserProfile> patchProfile(Map<String, dynamic> fields) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/profile'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(fields),
    );
    if (response.statusCode == 200) {
      return UserProfile.fromJson(
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('Failed to update profile (${response.statusCode})');
  }
}
