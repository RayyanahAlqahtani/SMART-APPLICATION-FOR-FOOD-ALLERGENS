class AllergenModel {
  final String id;
  final String name;
  final String category;

  const AllergenModel({
    required this.id,
    required this.name,
    required this.category,
  });

  AllergenModel copyWith({
    String? id,
    String? name,
    String? category,
  }) {
    return AllergenModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory AllergenModel.fromMap(Map<String, dynamic> map) {
    return AllergenModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
    );
  }

  factory AllergenModel.fromJson(Map<String, dynamic> json) =>
      AllergenModel.fromMap(json);

  // Firestore factory
  factory AllergenModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AllergenModel(
      id: id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'AllergenModel(id: $id, name: $name, category: $category)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AllergenModel &&
        other.id == id &&
        other.name == name &&
        other.category == category;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ category.hashCode;
}
