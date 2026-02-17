import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authSessionProvider = FutureProvider<bool>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'accessToken');
  return token != null && token.isNotEmpty;
});
