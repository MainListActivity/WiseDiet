class AllergenTag {
  final int id;
  final String label;
  final String? emoji;
  final String? description;
  final String? category;

  AllergenTag({
    required this.id,
    required this.label,
    this.emoji,
    this.description,
    this.category,
  });

  factory AllergenTag.fromJson(Map<String, dynamic> json) {
    return AllergenTag(
      id: json['id'],
      label: json['label'],
      emoji: json['emoji'],
      description: json['description'],
      category: json['category'],
    );
  }
}
