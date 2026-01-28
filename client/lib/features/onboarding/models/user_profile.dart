class UserProfile {
  String? gender;
  int? age;
  double? height;
  double? weight;
  Set<int> occupationTags;
  int familyMembers;

  UserProfile({
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.occupationTags = const {},
    this.familyMembers = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'occupationTagIds': occupationTags.join(','),
      'familyMembers': familyMembers,
    };
  }

  UserProfile copyWith({
    String? gender,
    int? age,
    double? height,
    double? weight,
    Set<int>? occupationTags,
    int? familyMembers,
  }) {
    return UserProfile(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      occupationTags: occupationTags ?? this.occupationTags,
      familyMembers: familyMembers ?? this.familyMembers,
    );
  }
}
