enum UserRole { admin, teacher, student }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImageUrl;
  final String? schoolId;
  final String? classId;
  final String? sectionId;
  final String? phone;
  final String? rollNumber;
  final String? designation;
  final bool? isActive;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
    this.schoolId,
    this.classId,
    this.sectionId,
    this.phone,
    this.rollNumber,
    this.designation,
    this.isActive,
    this.createdAt,
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
      sectionId: json['sectionId'],
      phone: json['phone'],
      rollNumber: json['rollNumber'],
      designation: json['designation'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
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
      'sectionId': sectionId,
      'phone': phone,
      'rollNumber': rollNumber,
      'designation': designation,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
