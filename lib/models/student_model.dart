import 'package:smart_school/models/school_models.dart';
import 'user_model.dart';

class Student {
  final String userId;
  final String rollId;
  final String classId;
  final String sectionId;
  final String guardianContact;
  final bool isActive;
  final User? user; // Joined user data
  final List<ClassRoom> embeddedClasses; // Embedded from API response
  final List<Section> embeddedSections; // Embedded from API response

  Student({
    required this.userId,
    required this.rollId,
    required this.classId,
    required this.sectionId,
    required this.guardianContact,
    this.isActive = true,
    this.user,
    this.embeddedClasses = const [],
    this.embeddedSections = const [],
  });

  bool get isDeleted => user?.deletedAt != null;

  /// Returns the first class name from embedded data, or null if not available.
  String? get className => embeddedClasses.isNotEmpty ? embeddedClasses.first.name : null;

  /// Returns the first section name from embedded data, or null if not available.
  String? get sectionName => embeddedSections.isNotEmpty ? embeddedSections.first.name : null;

  String? get address => user?.address;
  String? get fatherName => user?.fatherName;
  String? get motherName => user?.motherName;
  String? get guardianPhone => user?.guardianPhone ?? (guardianContact.isNotEmpty ? guardianContact : null);

  factory Student.fromJson(Map<String, dynamic> json) {
    // Parse embedded classes array (present in flat API response)
    final List<ClassRoom> classes = (json['classes'] as List<dynamic>? ?? [])
        .map((c) => ClassRoom.fromJson(c as Map<String, dynamic>))
        .toList();

    // Parse embedded sections array (present in flat API response)
    final List<Section> sections = (json['sections'] as List<dynamic>? ?? [])
        .map((s) => Section.fromJson(s as Map<String, dynamic>))
        .toList();

    // Derive classId and sectionId from embedded lists if not directly present
    final classIds = json['classIds'] as List<dynamic>?;
    final sectionIds = json['sectionIds'] as List<dynamic>?;

    final Map<String, dynamic> rawUserMap = json['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['user'])
        : Map<String, dynamic>.from(json);
    rawUserMap['address'] ??= json['address'];
    rawUserMap['fatherName'] ??= json['fatherName'];
    rawUserMap['motherName'] ??= json['motherName'];
    rawUserMap['guardianPhone'] ??= json['guardianPhone'] ?? json['guardianContact'];

    return Student(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      rollId: json['rollId']?.toString() ?? json['rollNumber']?.toString() ?? '',
      classId: json['classId']?.toString() ??
          (classIds?.isNotEmpty == true ? classIds!.first.toString() : '') ??
          (classes.isNotEmpty ? classes.first.id : ''),
      sectionId: json['sectionId']?.toString() ??
          (sectionIds?.isNotEmpty == true ? sectionIds!.first.toString() : '') ??
          (sections.isNotEmpty ? sections.first.id : ''),
      guardianContact: json['guardianPhone']?.toString() ??
          json['guardianContact']?.toString() ??
          json['phone']?.toString() ??
          '',
      isActive: json['isActive'] ?? true,
      user: User.fromJson(rawUserMap),
      embeddedClasses: classes,
      embeddedSections: sections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'rollId': rollId,
      'classId': classId,
      'sectionId': sectionId,
      'guardianContact': guardianContact,
      if (guardianPhone != null) 'guardianPhone': guardianPhone,
      if (address != null) 'address': address,
      if (fatherName != null) 'fatherName': fatherName,
      if (motherName != null) 'motherName': motherName,
      'isActive': isActive,
      if (user != null) 'user': user!.toJson(),
    };
  }
}
