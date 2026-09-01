import 'package:smart_school/models/school_models.dart';

class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? schoolId;
  final List<String> classIds;
  final List<String> sectionIds;
  final String? phone;
  final String? rollNumber;
  final String? designation;
  final bool? isActive;
  final String? avatar;
  final String? createdAt;
  final double? lat;
  final double? lon;
  final double? radius;
  final School? school;
  final ClassRoom? classEntity;
  final Section? section;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId,
    this.classIds = const [],
    this.sectionIds = const [],
    this.phone,
    this.rollNumber,
    this.designation,
    this.isActive,
    this.avatar,
    this.createdAt,
    this.lat,
    this.lon,
    this.radius,
    this.school,
    this.classEntity,
    this.section,
  });
}
