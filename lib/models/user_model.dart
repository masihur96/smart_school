enum UserRole {
  admin,
  teacher,
  student,
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
    };
  }
}
