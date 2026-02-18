import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wise_diet/features/onboarding/models/user_profile.dart';
import 'package:wise_diet/core/network/api_client.dart';
import 'package:wise_diet/features/onboarding/services/onboarding_service.dart';

class _TestAccessTokenProvider implements AccessTokenProvider {
  @override
  Future<String?> readAccessToken() async => null;
}

void main() {
  test('submitProfile should send profile payload', () async {
    Map<String, String>? capturedHeaders;
    Map<String, dynamic>? capturedBody;

    final mockClient = MockClient((request) async {
      capturedHeaders = request.headers;
      capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{}', 200);
    });

    final service = OnboardingService(
      client: ApiClient(
        httpClient: mockClient,
        accessTokenProvider: _TestAccessTokenProvider(),
      ),
    );

    await service.submitProfile(
      UserProfile(
        gender: 'Male',
        age: 30,
        height: 180,
        weight: 75,
        occupationTags: {1, 2},
        familyMembers: 3,
      ),
    );

    expect(capturedHeaders?['Content-Type'], 'application/json');
    expect(capturedBody?['familyMembers'], 3);
    expect(capturedBody?['occupationTagIds'], '1,2');
  });
}
