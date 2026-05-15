import 'school_models.dart';

class PeriodAttendanceResponse {
  final String message;
  final int statusCode;
  final PeriodAttendanceMetaData data;

  PeriodAttendanceResponse({
    required this.message,
    required this.statusCode,
    required this.data,
  });

  factory PeriodAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return PeriodAttendanceResponse(
      message: json['message'] ?? '',
      statusCode: json['statusCode'] ?? 0,
      data: PeriodAttendanceMetaData.fromJson(json['data'] ?? {}),
    );
  }
}

class PeriodAttendanceMetaData {
  final List<PeriodAttendance> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PeriodAttendanceMetaData({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PeriodAttendanceMetaData.fromJson(Map<String, dynamic> json) {
    return PeriodAttendanceMetaData(
      data: (json['data'] as List? ?? [])
          .map((e) => PeriodAttendance.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 50,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class PeriodAttendance {
  final String id;
  final String routineId;
  final String studentId;
  final String studentName;
  final String classId;
  final String sectionId;
  final String subjectId;
  final String teacherId;
  final String date;
  final String status;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? student;
  final ClassRoom? classInfo;
  final Section? sectionInfo;
  final Subject? subjectInfo;
  final Teacher? teacherInfo;
  final RoutineEntry? routineInfo;

  PeriodAttendance({
    required this.id,
    required this.routineId,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.teacherId,
    required this.date,
    required this.status,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.student,
    this.classInfo,
    this.sectionInfo,
    this.subjectInfo,
    this.teacherInfo,
    this.routineInfo,
  });

  factory PeriodAttendance.fromJson(Map<String, dynamic> json) {
    return PeriodAttendance(
      id: json['id'] ?? json['uuid'] ?? json['_id'] ?? '',
      routineId: json['routineId'] ?? json['routine_id'] ?? '',
      studentId: json['studentId'] ?? json['student_id'] ?? '',
      studentName: json['studentName'] ?? json['name'] ?? '',
      classId: json['classId'] ?? json['class_id'] ?? '',
      sectionId: json['sectionId'] ?? json['section_id'] ?? '',
      subjectId: json['subjectId'] ?? json['subject_id'] ?? '',
      teacherId: json['teacherId'] ?? json['teacher_id'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      schoolId: json['schoolId'] ?? json['school_id'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      student: json['student'],
      classInfo: json['class'] != null ? ClassRoom.fromJson(json['class']) : null,
      sectionInfo: json['section'] != null ? Section.fromJson(json['section']) : null,
      subjectInfo: json['subject'] != null ? Subject.fromJson(json['subject']) : null,
      teacherInfo: json['teacher'] != null ? Teacher.fromJson(json['teacher']) : null,
      routineInfo: json['routine'] != null ? RoutineEntry.fromJson(json['routine']) : null,
    );
  }
}
