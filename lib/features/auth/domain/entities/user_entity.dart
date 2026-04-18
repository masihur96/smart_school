import 'package:smart_school/models/school_models.dart';

class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? schoolId;
  final String? classId;
  final String? sectionId;
  final String? phone;
  final String? rollNumber;
  final String? designation;
  final bool? isActive;
  final String? createdAt;
  final double? lat;
  final double? lon;
  final double? radius;
  final School? school;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
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
    this.school,
  });
}
