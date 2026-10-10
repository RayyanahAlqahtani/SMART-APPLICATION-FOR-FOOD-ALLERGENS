class UserModel {
  final String userId;
  final String name;
  final String email;
  final int? age; // Nullable as it might not be set initially
  final String role; // 'user' or 'admin'
  final List<String> allergenList;
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.age,
    this.role = 'user',
    required this.allergenList,
    required this.createdAt,
  });

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    int? age,
    String? role,
    List<String>? allergenList,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      role: role ?? this.role,
      allergenList: allergenList ?? this.allergenList,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'age': age,
      'role': role,
      'allergenList': allergenList,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Alias for backward compatibility if needed, but toMap is standard for firestore
  Map<String, dynamic> toJson() => toMap();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      age: map['age'] as int?,
      role: map['role'] as String? ?? 'user',
      allergenList: List<String>.from(map['allergenList'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  // Firestore factory
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'].runtimeType.toString() == 'Timestamp') {
        parsedDate = data['createdAt'].toDate();
      } else {
        parsedDate =
            DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
      }
    }

    return UserModel(
      userId: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      age: data['age'] as int?,
      role: data['role'] as String? ?? 'user',
      allergenList: List<String>.from(data['allergenList'] ?? []),
      createdAt: parsedDate,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, name: $name, email: $email, age: $age, role: $role, allergenList: $allergenList, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.userId == userId &&
        other.name == name &&
        other.email == email &&
        other.age == age &&
        other.role == role &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        name.hashCode ^
        email.hashCode ^
        age.hashCode ^
        role.hashCode ^
        createdAt.hashCode;
  }
}
