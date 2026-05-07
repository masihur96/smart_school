import '../../../../models/school_models.dart';

class TeacherDashboardData {
  final DashboardAttendanceStatus? attendanceStatus;
  final List<TeacherSelfAttendance> myAttendanceList;
  final List<MyClassAttendStudent> myClassAttendStudents;
  final List<Homework> mySubmittedHomework;
  final Marquee? marqueeData;
  final List<Notice> recentNotice;
  final List<Exam> recentExamList;

  TeacherDashboardData({
    this.attendanceStatus,
    this.myAttendanceList = const [],
    this.myClassAttendStudents = const [],
    this.mySubmittedHomework = const [],
    this.marqueeData,
    this.recentNotice = const [],
    this.recentExamList = const [],
  });

  factory TeacherDashboardData.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardData(
      attendanceStatus: json['attendanceStatus'] != null
          ? DashboardAttendanceStatus.fromJson(json['attendanceStatus'])
          : null,
      myAttendanceList: (json['myAttendanceList'] as List? ?? [])
          .map((e) => TeacherSelfAttendance.fromJson(e))
          .toList(),
      myClassAttendStudents: (json['myClassAttendStudents'] as List? ?? [])
          .map((e) => MyClassAttendStudent.fromJson(e))
          .toList(),
      mySubmittedHomework: (json['mySubmittedHomework'] as List? ?? [])
          .map((e) => Homework.fromJson(e))
          .toList(),
      marqueeData: json['marqueeData'] != null
          ? Marquee.fromJson(json['marqueeData'])
          : null,
      recentNotice: (json['recentNotice'] as List? ?? [])
          .map((e) => Notice.fromJson(e))
          .toList(),
      recentExamList: (json['recentExamList'] as List? ?? [])
          .map((e) => Exam.fromJson(e))
          .toList(),
    );
  }
}

class DashboardAttendanceStatus {
  final String date;
  final String status;
  final String? clockInTime;
  final String? clockOutTime;
  final TeacherSelfAttendance? record;

  DashboardAttendanceStatus({
    required this.date,
    required this.status,
    this.clockInTime,
    this.clockOutTime,
    this.record,
  });

  factory DashboardAttendanceStatus.fromJson(Map<String, dynamic> json) {
    return DashboardAttendanceStatus(
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      clockInTime: json['clockInTime'],
      clockOutTime: json['clockOutTime'],
      record: json['record'] != null
          ? TeacherSelfAttendance.fromJson(json['record'])
          : null,
    );
  }
}

class MyClassAttendStudent {
  final String classId;
  final int present;
  final int absent;
  final int leave;
  final int total;
  final ClassRoom? classInfo;
  final double attendanceRate;

  MyClassAttendStudent({
    required this.classId,
    required this.present,
    required this.absent,
    required this.leave,
    required this.total,
    this.classInfo,
    required this.attendanceRate,
  });

  factory MyClassAttendStudent.fromJson(Map<String, dynamic> json) {
    return MyClassAttendStudent(
      classId: json['classId'] ?? '',
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      leave: json['leave'] ?? 0,
      total: json['total'] ?? 0,
      classInfo: json['classInfo'] != null
          ? ClassRoom.fromJson(json['classInfo'])
          : null,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
