enum UserRole { admin, teacher, student, superadmin }

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
  final double? lat;
  final double? lon;
  final double? radius;
  final DateTime? deletedAt;

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
    this.lat,
    this.lon,
    this.radius,
    this.deletedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: UserRole.values.cast<UserRole?>().firstWhere(
        (e) => e?.name == json['role'],
        orElse: () => UserRole.student,
      ) ?? UserRole.student,
      profileImageUrl: json['profileImageUrl']?.toString(),
      schoolId: json['schoolId']?.toString(),
      classId: json['classId']?.toString(),
      sectionId: json['sectionId']?.toString(),
      phone: json['phone']?.toString(),
      rollNumber: json['rollNumber']?.toString(),
      designation: json['designation']?.toString(),
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lon: json['lon'] != null ? double.tryParse(json['lon'].toString()) : null,
      radius: json['radius'] != null ? double.tryParse(json['radius'].toString()) : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
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
      'lat': lat,
      'lon': lon,
      'radius': radius,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
