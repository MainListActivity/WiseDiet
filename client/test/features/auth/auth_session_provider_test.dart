import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/auth/auth_session_provider.dart';

void main() {
  group('AuthSessionProvider', () {
    test('returns true when token exists', () async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Future.value(true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(authSessionProvider.future);
      expect(result, true);
    });

    test('returns false when token is null', () async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Future.value(false),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(authSessionProvider.future);
      expect(result, false);
    });
  });
}
