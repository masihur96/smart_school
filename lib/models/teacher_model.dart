import 'user_model.dart';

class Teacher {
  final String userId;
  final List<AssignedSubject> assignedSubjects;
  final String designation;
  final String? classId;
  final String? sectionId;
  final bool isActive;
  final User? user;

  final double? lat;
  final double? lon;
  final double? radius;

  Teacher({
    required this.userId, 
    this.assignedSubjects = const [], 
    this.designation = '',
    this.classId,
    this.sectionId,
    this.isActive = true,
    this.user,
    this.lat,
    this.lon,
    this.radius,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      userId: json['userId'] ?? json['id'] ?? json['_id'] ?? '',
      designation: json['designation'] ?? '',
      classId: json['classId'],
      sectionId: json['sectionId'],
      isActive: json['isActive'] ?? true,
      assignedSubjects: json['assignedSubjects'] != null 
          ? (json['assignedSubjects'] as List).map((e) => AssignedSubject.fromJson(e)).toList()
          : [],
      user: json['user'] != null ? User.fromJson(json['user']) : User.fromJson(json),
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lon: json['lon'] != null ? double.tryParse(json['lon'].toString()) : null,
      radius: json['radius'] != null ? double.tryParse(json['radius'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'designation': designation,
      'classId': classId,
      'sectionId': sectionId,
      'isActive': isActive,
      'assignedSubjects': assignedSubjects.map((e) => e.toJson()).toList(),
      if (user != null) 'user': user!.toJson(),
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (radius != null) 'radius': radius,
    };
  }
}

class AssignedSubject {
  final String classId;
  final String sectionId;
  final String subjectId;

  AssignedSubject({
    required this.classId,
    required this.sectionId,
    required this.subjectId,
  });

  factory AssignedSubject.fromJson(Map<String, dynamic> json) {
    return AssignedSubject(
      classId: json['classId'],
      sectionId: json['sectionId'],
      subjectId: json['subjectId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'classId': classId, 'sectionId': sectionId, 'subjectId': subjectId};
  }
}
