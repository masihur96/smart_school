import 'package:smart_school/models/school_models.dart';

class AuthResponseModel {
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

  AuthResponseModel({
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

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      role: json['role'] ?? "",
      schoolId: json['schoolId'],
      classIds: json['classIds'] != null
          ? List<String>.from(json['classIds'])
          : [],

      sectionIds: json['sectionIds'] != null
          ? List<String>.from(json['sectionIds'])
          : [],
      phone: json['phone'],
      rollNumber: json['rollNumber'],
      designation: json['designation'],
      isActive: json['isActive'],
      avatar: json['avatar']?.toString() ?? json['profileImageUrl']?.toString(),
      createdAt: json['createdAt']?.toString(),
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lon: json['lon'] != null ? double.tryParse(json['lon'].toString()) : null,
      radius: json['radius'] != null
          ? double.tryParse(json['radius'].toString())
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
      'role': role,
      'schoolId': schoolId,
      'classIds': classIds,
      'sectionIds': sectionIds,

      'phone': phone,
      'rollNumber': rollNumber,
      'designation': designation,
      'isActive': isActive,
      'avatar': avatar,
      'createdAt': createdAt,
      'lat': lat,
      'lon': lon,
      'radius': radius,
      'school': school?.toJson(),
      'class': classEntity?.toJson(),
      'section': section?.toJson(),
    };
  }
}
