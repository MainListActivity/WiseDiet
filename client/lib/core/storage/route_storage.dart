import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouteStorage {
  static const _key = 'last_route';

  static const _ignoredPrefixes = ['/login', '/onboarding'];

  Future<String?> getLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> saveLastRoute(String route) async {
    if (_ignoredPrefixes.any((prefix) => route.startsWith(prefix))) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, route);
  }

  Future<void> clearLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final routeStorageProvider = Provider<RouteStorage>((ref) => RouteStorage());
