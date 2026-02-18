import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/core/network/api_client.dart';
import 'package:wise_diet/core/network/api_client_provider.dart';

void main() {
  test('providers expose ApiClient type', () {
    final Provider<ApiClient> apiProvider = apiClientProvider;
    final Provider<ApiClient> authProvider = authApiClientProvider;

    expect(apiProvider, isNotNull);
    expect(authProvider, isNotNull);
  });
}
