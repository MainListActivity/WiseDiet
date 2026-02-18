import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final authController = ref.read(authControllerProvider.notifier);
  final client = ApiClient(
    onUnauthorized: authController.handleUnauthorized,
    onOnboardingRequired: authController.handleOnboardingRequired,
  );
  ref.onDispose(client.close);
  return client;
});

final authApiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return client;
});
