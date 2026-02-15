class UserProfile {
  String? gender;
  int? age;
  double? height;
  double? weight;
  Set<int> occupationTags;
  int familyMembers;
  Set<int> allergenTagIds;
  Set<int> dietaryPreferenceTagIds;
  List<String> customAvoidedIngredients;

  UserProfile({
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.occupationTags = const {},
    this.familyMembers = 1,
    this.allergenTagIds = const {},
    this.dietaryPreferenceTagIds = const {},
    this.customAvoidedIngredients = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'occupationTagIds': occupationTags.join(','),
      'familyMembers': familyMembers,
      'allergenTagIds': allergenTagIds.isNotEmpty ? allergenTagIds.join(',') : null,
      'dietaryPreferenceTagIds': dietaryPreferenceTagIds.isNotEmpty ? dietaryPreferenceTagIds.join(',') : null,
      'customAvoidedIngredients': customAvoidedIngredients.isNotEmpty ? customAvoidedIngredients.join(',') : null,
    };
  }

  UserProfile copyWith({
    String? gender,
    int? age,
    double? height,
    double? weight,
    Set<int>? occupationTags,
    int? familyMembers,
    Set<int>? allergenTagIds,
    Set<int>? dietaryPreferenceTagIds,
    List<String>? customAvoidedIngredients,
  }) {
    return UserProfile(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      occupationTags: occupationTags ?? this.occupationTags,
      familyMembers: familyMembers ?? this.familyMembers,
      allergenTagIds: allergenTagIds ?? this.allergenTagIds,
      dietaryPreferenceTagIds: dietaryPreferenceTagIds ?? this.dietaryPreferenceTagIds,
      customAvoidedIngredients: customAvoidedIngredients ?? this.customAvoidedIngredients,
    );
  }
}
