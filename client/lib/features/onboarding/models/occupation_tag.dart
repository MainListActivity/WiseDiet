class OccupationTag {
  final int id;
  final String label;
  final String? icon;
  final String category;

  OccupationTag({
    required this.id,
    required this.label,
    this.icon,
    required this.category,
  });

  factory OccupationTag.fromJson(Map<String, dynamic> json) {
    return OccupationTag(
      id: json['id'],
      label: json['label'],
      icon: json['icon'],
      category: json['category'] ?? 'Occupation',
    );
  }
}
