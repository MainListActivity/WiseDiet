import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wise_diet/core/storage/route_storage.dart';

void main() {
  group('RouteStorage', () {
    late RouteStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = RouteStorage();
    });

    test('returns null when no route is saved', () async {
      final route = await storage.getLastRoute();
      expect(route, isNull);
    });

    test('saves and retrieves a route', () async {
      await storage.saveLastRoute('/home');
      final route = await storage.getLastRoute();
      expect(route, '/home');
    });

    test('clears the saved route', () async {
      await storage.saveLastRoute('/home');
      await storage.clearLastRoute();
      final route = await storage.getLastRoute();
      expect(route, isNull);
    });

    test('overwrites previously saved route', () async {
      await storage.saveLastRoute('/home');
      await storage.saveLastRoute('/settings');
      final route = await storage.getLastRoute();
      expect(route, '/settings');
    });

    test('does not save login route', () async {
      await storage.saveLastRoute('/home');
      await storage.saveLastRoute('/login');
      final route = await storage.getLastRoute();
      expect(route, '/home');
    });

    test('does not save onboarding routes', () async {
      await storage.saveLastRoute('/home');
      await storage.saveLastRoute('/onboarding/basic-info');
      final route = await storage.getLastRoute();
      expect(route, '/home');
    });
  });
}
