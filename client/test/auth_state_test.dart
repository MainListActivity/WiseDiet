import 'package:flutter_test/flutter_test.dart';
import 'package:wise_diet/features/auth/auth_state.dart';

void main() {
  test('starts logged out', () {
    final state = AuthState.initial();
    expect(state.isLoggedIn, false);
  });
}
