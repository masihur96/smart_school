import 'package:smart_school/models/school_models.dart';
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
  final DateTime? deletedAt;
  final List<ClassRoom> embeddedClasses; // Embedded from API response
  final List<Section> embeddedSections; // Embedded from API response

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
    this.deletedAt,
    this.embeddedClasses = const [],
    this.embeddedSections = const [],
  });

  bool get isDeleted => deletedAt != null;

  String? get address => user?.address;
  String? get fatherName => user?.fatherName;
  String? get motherName => user?.motherName;
  String? get guardianPhone => user?.guardianPhone;

  factory Teacher.fromJson(Map<String, dynamic> json) {
    // Parse embedded classes array (present in flat API response)
    final List<ClassRoom> classes = (json['classes'] as List<dynamic>? ?? [])
        .map((c) => ClassRoom.fromJson(c as Map<String, dynamic>))
        .toList();

    // Parse embedded sections array (present in flat API response)
    final List<Section> sections = (json['sections'] as List<dynamic>? ?? [])
        .map((s) => Section.fromJson(s as Map<String, dynamic>))
        .toList();

    // Derive classId / sectionId from arrays when not set as a scalar
    final classIds = json['classIds'] as List<dynamic>?;
    final sectionIds = json['sectionIds'] as List<dynamic>?;

    final Map<String, dynamic> rawUserMap = json['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['user'])
        : Map<String, dynamic>.from(json);
    rawUserMap['address'] ??= json['address'];
    rawUserMap['fatherName'] ??= json['fatherName'];
    rawUserMap['motherName'] ??= json['motherName'];
    rawUserMap['guardianPhone'] ??= json['guardianPhone'] ?? json['guardianContact'];

    return Teacher(
      userId: json['userId'] ?? json['id'] ?? json['_id'] ?? '',
      designation: json['designation'] ?? '',
      classId: json['classId'] ??
          (classIds?.isNotEmpty == true ? classIds!.first.toString() : null) ??
          (classes.isNotEmpty ? classes.first.id : null),
      sectionId: json['sectionId'] ??
          (sectionIds?.isNotEmpty == true ? sectionIds!.first.toString() : null) ??
          (sections.isNotEmpty ? sections.first.id : null),
      isActive: json['isActive'] ?? true,
      assignedSubjects: json['assignedSubjects'] != null 
          ? (json['assignedSubjects'] as List).map((e) => AssignedSubject.fromJson(e)).toList()
          : [],
      user: User.fromJson(rawUserMap),
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lon: json['lon'] != null ? double.tryParse(json['lon'].toString()) : null,
      radius: json['radius'] != null ? double.tryParse(json['radius'].toString()) : null,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
      embeddedClasses: classes,
      embeddedSections: sections,
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
      if (address != null) 'address': address,
      if (fatherName != null) 'fatherName': fatherName,
      if (motherName != null) 'motherName': motherName,
      if (guardianPhone != null) 'guardianPhone': guardianPhone,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (radius != null) 'radius': radius,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
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
