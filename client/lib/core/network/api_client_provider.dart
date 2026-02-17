import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/auth_controller.dart';
import 'api_client.dart';

final apiClientProvider = Provider<http.Client>((ref) {
  final authController = ref.read(authControllerProvider.notifier);
  final client = ApiClient(
    onUnauthorized: authController.handleUnauthorized,
    onOnboardingRequired: authController.handleOnboardingRequired,
  );
  ref.onDispose(client.close);
  return client;
});

final authApiClientProvider = Provider<http.Client>((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return client;
});
