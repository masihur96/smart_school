import 'package:smart_school/models/school_models.dart';

enum UserRole { admin, teacher, student, superadmin }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatar;
  final String? schoolId;
  final List<String> classIds;
  final List<String> sectionIds;
  final String? phone;
  final String? rollNumber;
  final String? designation;
  final bool? isActive;
  final DateTime? createdAt;
  final double? lat;
  final double? lon;
  final double? radius;
  final DateTime? deletedAt;
  final School? school;
  final ClassRoom? classEntity;
  final Section? section;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.schoolId,
    this.classIds = const [],
    this.sectionIds = const [],
    this.phone,
    this.rollNumber,
    this.designation,
    this.isActive,
    this.createdAt,
    this.lat,
    this.lon,
    this.radius,
    this.deletedAt,
    this.school,
    this.classEntity,
    this.section,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role:
          UserRole.values.cast<UserRole?>().firstWhere(
            (e) => e?.name == json['role'],
            orElse: () => UserRole.student,
          ) ??
          UserRole.student,
      avatar: json['avatar']?.toString() ?? "",
      schoolId: json['schoolId']?.toString(),
      classIds: json['classIds'] != null
          ? List<String>.from(json['classIds'])
          : [],

      sectionIds: json['sectionIds'] != null
          ? List<String>.from(json['sectionIds'])
          : [],
      phone: json['phone']?.toString(),
      rollNumber: json['rollNumber']?.toString(),
      designation: json['designation']?.toString(),
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lon: json['lon'] != null ? double.tryParse(json['lon'].toString()) : null,
      radius: json['radius'] != null
          ? double.tryParse(json['radius'].toString())
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
      school: json['school'] != null ? School.fromJson(json['school']) : null,
      classEntity: json['class'] != null ? ClassRoom.fromJson(json['class']) : null,
      section: json['section'] != null ? Section.fromJson(json['section']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'avatar': avatar,
      'schoolId': schoolId,
      'classIds': classIds,

      'sectionIds': sectionIds,
      'phone': phone,
      'rollNumber': rollNumber,
      'designation': designation,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'lat': lat,
      'lon': lon,
      'radius': radius,
      'deletedAt': deletedAt?.toIso8601String(),
      'school': school?.toJson(),
      'class': classEntity?.toJson(),
      'section': section?.toJson(),
    };
  }
}
