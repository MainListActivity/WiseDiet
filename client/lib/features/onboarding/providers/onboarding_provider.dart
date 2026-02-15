import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';

class OnboardingNotifier extends StateNotifier<UserProfile> {
  OnboardingNotifier() : super(UserProfile());

  void updateBasicInfo({
    String? gender,
    int? age,
    double? height,
    double? weight,
    int? familyMembers,
  }) {
    state = state.copyWith(
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      familyMembers: familyMembers,
    );
  }

  void updateTags(Set<int> tags) {
    state = state.copyWith(occupationTags: tags);
  }

  void updateFamilyMembers(int count) {
    state = state.copyWith(familyMembers: count);
  }

  void updateAllergens(Set<int> ids) {
    state = state.copyWith(allergenTagIds: ids);
  }

  void updateDietaryPreferences(Set<int> ids) {
    state = state.copyWith(dietaryPreferenceTagIds: ids);
  }

  void updateCustomAvoidedIngredients(List<String> ingredients) {
    state = state.copyWith(customAvoidedIngredients: ingredients);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, UserProfile>((ref) {
      return OnboardingNotifier();
    });
