import 'package:smart_school/models/school_models.dart';

class StudentDashboardData {
  final TodayAttendanceStatus? todayAttendanceStatus;
  final MyAttendanceList? myAttendanceList;
  final List<StudentHomework> recentHomework;
  final MarqueeData? marqueeData;
  final List<Notice> myRecentNotice;
  final List<MyRecentExamWithResult> myRecentExamListWithResult;

  StudentDashboardData({
    this.todayAttendanceStatus,
    this.myAttendanceList,
    this.recentHomework = const [],
    this.marqueeData,
    this.myRecentNotice = const [],
    this.myRecentExamListWithResult = const [],
  });

  factory StudentDashboardData.fromJson(Map<String, dynamic> json) {
    return StudentDashboardData(
      todayAttendanceStatus: json['todayAttendanceStatus'] != null
          ? TodayAttendanceStatus.fromJson(json['todayAttendanceStatus'])
          : null,
      myAttendanceList: json['myAttendanceList'] != null
          ? MyAttendanceList.fromJson(json['myAttendanceList'])
          : null,
      recentHomework: (json['recentHomework'] as List? ?? [])
          .map((e) => StudentHomework.fromJson(e))
          .toList(),
      marqueeData: json['marqueeData'] != null
          ? MarqueeData.fromJson(json['marqueeData'])
          : null,
      myRecentNotice: (json['myRecentNotice'] as List? ?? [])
          .map((e) => Notice.fromJson(e))
          .toList(),
      myRecentExamListWithResult:
          (json['myRecentExamListWithResult'] as List? ?? [])
              .map((e) => MyRecentExamWithResult.fromJson(e))
              .toList(),
    );
  }
}

class TodayAttendanceStatus {
  final String date;
  final String status;
  final Attendance? record;

  TodayAttendanceStatus({
    required this.date,
    required this.status,
    this.record,
  });

  factory TodayAttendanceStatus.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceStatus(
      date: json['date'] ?? '',
      status: json['status'] ?? 'not-marked',
      record: json['record'] != null ? Attendance.fromJson(json['record']) : null,
    );
  }
}

class MyAttendanceList {
  final AttendanceSummary? summary;
  final List<Attendance> records;

  MyAttendanceList({
    this.summary,
    this.records = const [],
  });

  factory MyAttendanceList.fromJson(Map<String, dynamic> json) {
    return MyAttendanceList(
      summary: json['summary'] != null
          ? AttendanceSummary.fromJson(json['summary'])
          : null,
      records: (json['records'] as List? ?? [])
          .map((e) => Attendance.fromJson(e))
          .toList(),
    );
  }
}

class AttendanceSummary {
  final int total;
  final int present;
  final int absent;
  final int leave;
  final double attendanceRate;

  AttendanceSummary({
    this.total = 0,
    this.present = 0,
    this.absent = 0,
    this.leave = 0,
    this.attendanceRate = 0.0,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      total: json['total'] ?? 0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      leave: json['leave'] ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MarqueeData {
  final String id;
  final String text;
  final String type;

  MarqueeData({
    required this.id,
    required this.text,
    required this.type,
  });

  factory MarqueeData.fromJson(Map<String, dynamic> json) {
    return MarqueeData(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class MyRecentExamWithResult {
  final Exam? exam;
  final List<Result> myMarks;
  final ExamResultSummary? result;

  MyRecentExamWithResult({
    this.exam,
    this.myMarks = const [],
    this.result,
  });

  factory MyRecentExamWithResult.fromJson(Map<String, dynamic> json) {
    return MyRecentExamWithResult(
      exam: json['exam'] != null ? Exam.fromJson(json['exam']) : null,
      myMarks: (json['myMarks'] as List? ?? [])
          .map((e) => Result.fromJson(e))
          .toList(),
      result: json['result'] != null
          ? ExamResultSummary.fromJson(json['result'])
          : null,
    );
  }
}

class ExamResultSummary {
  final int totalObtained;
  final int totalMax;
  final double percentage;
  final String grade;
  final bool hasResult;

  ExamResultSummary({
    this.totalObtained = 0,
    this.totalMax = 0,
    this.percentage = 0.0,
    this.grade = '',
    this.hasResult = false,
  });

  factory ExamResultSummary.fromJson(Map<String, dynamic> json) {
    return ExamResultSummary(
      totalObtained: json['totalObtained'] ?? 0,
      totalMax: json['totalMax'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      grade: json['grade'] ?? '',
      hasResult: json['hasResult'] ?? false,
    );
  }
}
