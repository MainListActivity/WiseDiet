class DietaryPreferenceTag {
  final int id;
  final String label;
  final String? emoji;

  DietaryPreferenceTag({
    required this.id,
    required this.label,
    this.emoji,
  });

  factory DietaryPreferenceTag.fromJson(Map<String, dynamic> json) {
    return DietaryPreferenceTag(
      id: json['id'],
      label: json['label'],
      emoji: json['emoji'],
    );
  }
}
