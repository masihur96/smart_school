enum UserRole { admin, teacher, student }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImageUrl;
  final String? schoolId;
  final String? classId;
  final String? phone;
  final String? rollNumber;
  final String? designation;
  final bool? isActive;


  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
    this.schoolId,
    this.classId,
    this.phone,
    this.rollNumber,
    this.designation,
    this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.values.cast<UserRole?>().firstWhere(
        (e) => e?.name == json['role'],
        orElse: () => UserRole.student,
      ) ?? UserRole.student,
      profileImageUrl: json['profileImageUrl'],
      schoolId: json['schoolId'],
      classId: json['classId'],
      phone: json['phone'],
      rollNumber: json['rollNumber'],
      designation: json['designation'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'schoolId': schoolId,
      'classId': classId,
      'phone': phone,
      'rollNumber': rollNumber,
      'designation': designation,
      'isActive': isActive,
    };
  }
}
