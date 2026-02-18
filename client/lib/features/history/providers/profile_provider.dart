import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import '../../onboarding/models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  late ProfileService _service;

  @override
  Future<UserProfile> build() async {
    final client = ref.watch(apiClientProvider);
    _service = ProfileService(client: client);
    return _service.getProfile();
  }

  Future<void> updateField(Map<String, dynamic> fields) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.patchProfile(fields));
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);
