class AdminDashboardData {
  final AttendTeacher attendTeacher;
  final AttendStudent attendStudent;
  final List<RecentHomework> recentHomework;
  final List<RecentNotice> recentNotice;
  final List<CurrentExam> currentExam;

  AdminDashboardData({
    required this.attendTeacher,
    required this.attendStudent,
    required this.recentHomework,
    required this.recentNotice,
    required this.currentExam,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      attendTeacher: AttendTeacher.fromJson(json['attendTeacher'] ?? {}),
      attendStudent: AttendStudent.fromJson(json['attendStudent'] ?? {}),
      recentHomework: (json['recentHomework'] as List<dynamic>?)
              ?.map((e) => RecentHomework.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentNotice: (json['recentNotice'] as List<dynamic>?)
              ?.map((e) => RecentNotice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentExam: (json['currentExam'] as List<dynamic>?)
              ?.map((e) => CurrentExam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AttendTeacher {
  final String date;
  final int totalTeachers;
  final int present;
  final int absent;
  final double attendanceRate;
  final List<TeacherRecentRecord> recentRecords;

  AttendTeacher({
    required this.date,
    required this.totalTeachers,
    required this.present,
    required this.absent,
    required this.attendanceRate,
    required this.recentRecords,
  });

  factory AttendTeacher.fromJson(Map<String, dynamic> json) {
    return AttendTeacher(
      date: json['date']?.toString() ?? '',
      totalTeachers: int.tryParse(json['totalTeachers']?.toString() ?? '0') ?? 0,
      present: int.tryParse(json['present']?.toString() ?? '0') ?? 0,
      absent: int.tryParse(json['absent']?.toString() ?? '0') ?? 0,
      attendanceRate: double.tryParse(json['attendanceRate']?.toString() ?? '0') ?? 0.0,
      recentRecords: (json['recentRecords'] as List<dynamic>?)
              ?.map((e) => TeacherRecentRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AttendStudent {
  final String date;
  final int totalStudents;
  final int recorded;
  final int present;
  final int absent;
  final int leave;
  final int late;
  final double attendanceRate;
  final List<StudentAttendanceRecord> data;
  final MonthlySummary? monthlySummary;
  final List<DailyAttendance> dailyAttendance;

  AttendStudent({
    required this.date,
    required this.totalStudents,
    required this.recorded,
    required this.present,
    required this.absent,
    required this.leave,
    this.late = 0,
    required this.attendanceRate,
    required this.data,
    this.monthlySummary,
    this.dailyAttendance = const [],
  });

  factory AttendStudent.fromJson(Map<String, dynamic> json) {
    return AttendStudent(
      date: json['date']?.toString() ?? '',
      totalStudents: int.tryParse(json['totalStudents']?.toString() ?? '0') ?? 0,
      recorded: int.tryParse(json['recorded']?.toString() ?? '0') ?? 0,
      present: int.tryParse(json['present']?.toString() ?? '0') ?? 0,
      absent: int.tryParse(json['absent']?.toString() ?? '0') ?? 0,
      leave: int.tryParse(json['leave']?.toString() ?? '0') ?? 0,
      late: int.tryParse(json['late']?.toString() ?? '0') ?? 0,
      attendanceRate: double.tryParse(json['attendanceRate']?.toString() ?? '0') ?? 0.0,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => StudentAttendanceRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlySummary: json['monthlySummary'] != null && json['monthlySummary'] is Map<String, dynamic>
          ? MonthlySummary.fromJson(json['monthlySummary'] as Map<String, dynamic>)
          : null,
      dailyAttendance: (json['dailyAttendance'] as List<dynamic>?)
              ?.map((e) => DailyAttendance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MonthlySummary {
  final int month;
  final String monthName;
  final int year;
  final int totalStudents;
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final int totalLeave;
  final int totalAttended;
  final int totalRecords;
  final double attendanceRate;
  final int daysRecorded;
  final int daysInMonth;

  MonthlySummary({
    required this.month,
    required this.monthName,
    required this.year,
    required this.totalStudents,
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
    required this.totalLeave,
    required this.totalAttended,
    required this.totalRecords,
    required this.attendanceRate,
    required this.daysRecorded,
    required this.daysInMonth,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      month: int.tryParse(json['month']?.toString() ?? '0') ?? 0,
      monthName: json['monthName']?.toString() ?? '',
      year: int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      totalStudents: int.tryParse(json['totalStudents']?.toString() ?? '0') ?? 0,
      totalPresent: int.tryParse(json['totalPresent']?.toString() ?? '0') ?? 0,
      totalLate: int.tryParse(json['totalLate']?.toString() ?? '0') ?? 0,
      totalAbsent: int.tryParse(json['totalAbsent']?.toString() ?? '0') ?? 0,
      totalLeave: int.tryParse(json['totalLeave']?.toString() ?? '0') ?? 0,
      totalAttended: int.tryParse(json['totalAttended']?.toString() ?? '0') ?? 0,
      totalRecords: int.tryParse(json['totalRecords']?.toString() ?? '0') ?? 0,
      attendanceRate: double.tryParse(json['attendanceRate']?.toString() ?? '0') ?? 0.0,
      daysRecorded: int.tryParse(json['daysRecorded']?.toString() ?? '0') ?? 0,
      daysInMonth: int.tryParse(json['daysInMonth']?.toString() ?? '0') ?? 0,
    );
  }
}

class DailyAttendance {
  final String date;
  final int day;
  final String dayOfWeek;
  final int present;
  final int late;
  final int absent;
  final int leave;
  final int totalPresent;
  final int total;
  final double attendanceRate;
  final bool hasData;
  final bool isFuture;

  DailyAttendance({
    required this.date,
    required this.day,
    required this.dayOfWeek,
    required this.present,
    required this.late,
    required this.absent,
    required this.leave,
    required this.totalPresent,
    required this.total,
    required this.attendanceRate,
    required this.hasData,
    required this.isFuture,
  });

  factory DailyAttendance.fromJson(Map<String, dynamic> json) {
    return DailyAttendance(
      date: json['date']?.toString() ?? '',
      day: int.tryParse(json['day']?.toString() ?? '0') ?? 0,
      dayOfWeek: json['dayOfWeek']?.toString() ?? '',
      present: int.tryParse(json['present']?.toString() ?? '0') ?? 0,
      late: int.tryParse(json['late']?.toString() ?? '0') ?? 0,
      absent: int.tryParse(json['absent']?.toString() ?? '0') ?? 0,
      leave: int.tryParse(json['leave']?.toString() ?? '0') ?? 0,
      totalPresent: int.tryParse(json['totalPresent']?.toString() ?? '0') ?? 0,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      attendanceRate: double.tryParse(json['attendanceRate']?.toString() ?? '0') ?? 0.0,
      hasData: json['hasData'] == true || json['hasData']?.toString() == 'true',
      isFuture: json['isFuture'] == true || json['isFuture']?.toString() == 'true',
    );
  }
}

class StudentAttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String designation;
  final String status;
  final String date;
  final String className;
  final String sectionName;
  final String? subjectId;
  final String? subjectName;

  StudentAttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.designation,
    required this.status,
    required this.date,
    required this.className,
    this.sectionName = '',
    this.subjectId,
    this.subjectName,
  });

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    String extractSectionName(Map<String, dynamic> j) {
      if (j['section'] is Map && j['section']['name'] != null) {
        return j['section']['name'].toString();
      }
      if (j['sectionInfo'] is Map && j['sectionInfo']['name'] != null) {
        return j['sectionInfo']['name'].toString();
      }
      if (j['sectionName'] != null && j['sectionName'].toString().isNotEmpty) {
        return j['sectionName'].toString();
      }
      if (j['section'] != null && j['section'] is String) {
        return j['section'].toString();
      }
      if (j['student'] is Map) {
        final s = j['student'] as Map<String, dynamic>;
        if (s['section'] is Map && s['section']['name'] != null) {
          return s['section']['name'].toString();
        }
        if (s['sectionInfo'] is Map && s['sectionInfo']['name'] != null) {
          return s['sectionInfo']['name'].toString();
        }
        if (s['sectionName'] != null && s['sectionName'].toString().isNotEmpty) {
          return s['sectionName'].toString();
        }
        if (s['section'] != null && s['section'] is String) {
          return s['section'].toString();
        }
        if (s['sections'] is List && (s['sections'] as List).isNotEmpty) {
          final firstSec = (s['sections'] as List).first;
          if (firstSec is Map && firstSec['name'] != null) {
            return firstSec['name'].toString();
          }
        }
      }
      return '';
    }

    return StudentAttendanceRecord(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? json['student']?['name']?.toString() ?? 'Unknown',
      rollNumber: json['student']?['rollNumber']?.toString() ?? '',
      designation: json['student']?['designation']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      className: json['class']?['name']?.toString() ?? json['className']?.toString() ?? json['classInfo']?['name']?.toString() ?? '',
      sectionName: extractSectionName(json),
      subjectId: json['subjectId']?.toString(),
      subjectName: json['subject']?['name']?.toString() ?? json['subjectInfo']?['name']?.toString(),
    );
  }
}

class RecentHomework {
  final String id;
  final String title;
  final String description;
  final String dueDate;
  final String className;
  final String subjectName;
  final String sectionName;
  final String teacherName;
  final String? teacherAvatar;
  final String? classId;
  final String? subjectId;
  final String? teacherId;
  final String? sectionId;
  final String? schoolId;
  final String? subjectCode;
  final String? createdAt;

  RecentHomework({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.className,
    required this.subjectName,
    required this.sectionName,
    required this.teacherName,
    this.teacherAvatar,
    this.classId,
    this.subjectId,
    this.teacherId,
    this.sectionId,
    this.schoolId,
    this.subjectCode,
    this.createdAt,
  });

  factory RecentHomework.fromJson(Map<String, dynamic> json) {
    return RecentHomework(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      className: json['classInfo']?['name']?.toString() ?? json['className']?.toString() ?? '',
      subjectName: json['subjectInfo']?['name']?.toString() ?? json['subjectName']?.toString() ?? '',
      sectionName: json['sectionInfo']?['name']?.toString() ?? json['sectionName']?.toString() ?? '',
      teacherName: json['teacherInfo']?['name']?.toString() ?? json['teacherName']?.toString() ?? '',
      teacherAvatar: json['teacherInfo']?['avatar']?.toString() ?? json['teacherAvatar']?.toString(),
      classId: json['classId']?.toString(),
      subjectId: json['subjectId']?.toString(),
      teacherId: json['teacherId']?.toString(),
      sectionId: json['sectionId']?.toString(),
      schoolId: json['schoolId']?.toString(),
      subjectCode: json['subjectInfo']?['code']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class RecentNotice {
  final String id;
  final String title;
  final String content;
  final String targetAudience;
  final bool isImportent;
  final String postedBy;
  final String createdAt;
  final String? avatar;
  final String? schoolId;

  RecentNotice({
    required this.id,
    required this.title,
    required this.content,
    required this.targetAudience,
    required this.isImportent,
    required this.postedBy,
    required this.createdAt,
    this.avatar,
    this.schoolId,
  });

  factory RecentNotice.fromJson(Map<String, dynamic> json) {
    return RecentNotice(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      targetAudience: json['targetAudience']?.toString() ?? '',
      isImportent: json['isImportent'] == true ||
          json['isImportent'] == 'true' ||
          json['isImportant'] == true ||
          json['isImportant'] == 'true',
      postedBy: json['postedBy']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      schoolId: json['schoolId']?.toString(),
    );
  }
}

class CurrentExam {
  final String id;
  final String examName;
  final String description;
  final String startDate;
  final String endDate;
  final bool isPublished;
  final String status;
  final List<ExamAssignmentSummary> assignments;

  CurrentExam({
    required this.id,
    required this.examName,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isPublished,
    this.status = '',
    this.assignments = const [],
  });

  factory CurrentExam.fromJson(Map<String, dynamic> json) {
    return CurrentExam(
      id: json['id']?.toString() ?? '',
      examName: json['exam_name']?.toString() ?? json['examName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? json['startDate']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? json['endDate']?.toString() ?? '',
      isPublished: json['isPublished'] == true ||
          json['isPublished'] == 'true' ||
          json['is_published'] == true ||
          json['is_published'] == 'true',
      status: json['status']?.toString() ?? '',
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => ExamAssignmentSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ExamAssignmentSummary {
  final String id;
  final String examId;
  final String className;
  final String subjectName;
  final String examinerName;
  final String date;
  final String? startTime;
  final String? endTime;
  final String syllabus;

  ExamAssignmentSummary({
    required this.id,
    required this.examId,
    required this.className,
    required this.subjectName,
    required this.examinerName,
    required this.date,
    this.startTime,
    this.endTime,
    required this.syllabus,
  });

  factory ExamAssignmentSummary.fromJson(Map<String, dynamic> json) {
    return ExamAssignmentSummary(
      id: json['id']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      className: json['class']?['name']?.toString() ?? '',
      subjectName: json['subject']?['name']?.toString() ?? '',
      examinerName: json['examiner']?['name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      syllabus: json['syllabus']?.toString() ?? '',
    );
  }
}

class TeacherRecentRecord {
  final String id;
  final String teacherName;
  final String designation;
  final String date;
  final String time;
  final String startTime;
  final String? endTime;
  final String status;
  final String lat;
  final String lon;

  TeacherRecentRecord({
    required this.id,
    required this.teacherName,
    required this.designation,
    required this.date,
    required this.time,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.lat,
    required this.lon,
  });

  factory TeacherRecentRecord.fromJson(Map<String, dynamic> json) {
    return TeacherRecentRecord(
      id: json['id']?.toString() ?? '',
      teacherName: json['teacher']?['name']?.toString() ?? 'Unknown',
      designation: json['teacher']?['designation']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString(),
      status: json['status']?.toString() ?? '',
      lat: json['lat']?.toString() ?? '',
      lon: json['lon']?.toString() ?? '',
    );
  }
}

class MonthlyAttendanceOverview {
  final int year;
  final List<MonthlyAttendanceData> data;

  MonthlyAttendanceOverview({
    required this.year,
    required this.data,
  });

  factory MonthlyAttendanceOverview.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceOverview(
      year: json['year'] ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => MonthlyAttendanceData.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MonthlyAttendanceData {
  final int month;
  final int totalPresent;
  final int totalAbsent;
  final int totalLeave;
  final int totalLate;
  final double attendancePercentage;

  MonthlyAttendanceData({
    required this.month,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLeave,
    required this.totalLate,
    required this.attendancePercentage,
  });

  factory MonthlyAttendanceData.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceData(
      month: json['month'] ?? 0,
      totalPresent: json['totalPresent'] ?? 0,
      totalAbsent: json['totalAbsent'] ?? 0,
      totalLeave: json['totalLeave'] ?? 0,
      totalLate: json['totalLate'] ?? 0,
      attendancePercentage: (json['attendancePercentage'] ?? 0).toDouble(),
    );
  }
}

class TeacherPerformance {
  final String teacherId;
  final String name;
  final String? avatar;
  final String designation;
  final PerformanceAttendance attendance;
  final PerformanceHomework homework;

  TeacherPerformance({
    required this.teacherId,
    required this.name,
    this.avatar,
    required this.designation,
    required this.attendance,
    required this.homework,
  });

  factory TeacherPerformance.fromJson(Map<String, dynamic> json) {
    return TeacherPerformance(
      teacherId: json['teacherId'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ??
          json['avatarUrl'] ??
          json['photo'] ??
          json['image'] ??
          json['profileImage'] ??
          json['teacher']?['avatar'] ??
          json['teacher']?['avatarUrl'] ??
          json['teacher']?['photo'] ??
          json['teacher']?['user']?['avatar'] ??
          json['user']?['avatar'],
      designation: json['designation'] ?? '',
      attendance: PerformanceAttendance.fromJson(json['attendance'] ?? {}),
      homework: PerformanceHomework.fromJson(json['homework'] ?? {}),
    );
  }
}

class PerformanceAttendance {
  final int totalWorkingDays;
  final int presentDays;
  final double percentage;

  PerformanceAttendance({
    required this.totalWorkingDays,
    required this.presentDays,
    required this.percentage,
  });

  factory PerformanceAttendance.fromJson(Map<String, dynamic> json) {
    return PerformanceAttendance(
      totalWorkingDays: json['totalWorkingDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class PerformanceHomework {
  final int totalProvided;
  final int target;
  final double percentage;

  PerformanceHomework({
    required this.totalProvided,
    required this.target,
    required this.percentage,
  });

  factory PerformanceHomework.fromJson(Map<String, dynamic> json) {
    return PerformanceHomework(
      totalProvided: json['totalProvided'] ?? 0,
      target: json['target'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class StudentPerformance {
  final String studentId;
  final String name;
  final String? avatar;
  final String? rollNumber;
  final PerformanceClass? classInfo;
  final PerformanceSection? section;
  final PerformanceAttendance attendance;
  final StudentPerformanceHomework homework;
  final StudentPerformanceExams exams;

  StudentPerformance({
    required this.studentId,
    required this.name,
    this.avatar,
    this.rollNumber,
    this.classInfo,
    this.section,
    required this.attendance,
    required this.homework,
    required this.exams,
  });

  factory StudentPerformance.fromJson(Map<String, dynamic> json) {
    return StudentPerformance(
      studentId: json['studentId'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ??
          json['avatarUrl'] ??
          json['photo'] ??
          json['image'] ??
          json['profileImage'] ??
          json['student']?['avatar'] ??
          json['student']?['avatarUrl'] ??
          json['student']?['photo'] ??
          json['student']?['user']?['avatar'] ??
          json['user']?['avatar'],
      rollNumber: json['rollNumber'],
      classInfo: json['class'] != null ? PerformanceClass.fromJson(json['class']) : null,
      section: json['section'] != null ? PerformanceSection.fromJson(json['section']) : null,
      attendance: PerformanceAttendance.fromJson(json['attendance'] ?? {}),
      homework: StudentPerformanceHomework.fromJson(json['homework'] ?? {}),
      exams: StudentPerformanceExams.fromJson(json['exams'] ?? {}),
    );
  }
}

class PerformanceClass {
  final String id;
  final String name;

  PerformanceClass({required this.id, required this.name});

  factory PerformanceClass.fromJson(Map<String, dynamic> json) {
    return PerformanceClass(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class PerformanceSection {
  final String id;
  final String name;

  PerformanceSection({required this.id, required this.name});

  factory PerformanceSection.fromJson(Map<String, dynamic> json) {
    return PerformanceSection(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class StudentPerformanceHomework {
  final int totalAssigned;
  final int totalDone;
  final double percentage;

  StudentPerformanceHomework({
    required this.totalAssigned,
    required this.totalDone,
    required this.percentage,
  });

  factory StudentPerformanceHomework.fromJson(Map<String, dynamic> json) {
    return StudentPerformanceHomework(
      totalAssigned: json['totalAssigned'] ?? 0,
      totalDone: json['totalDone'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class StudentPerformanceExams {
  final num totalMarksObtained;
  final num totalMaximumMarks;
  final double percentage;

  StudentPerformanceExams({
    required this.totalMarksObtained,
    required this.totalMaximumMarks,
    required this.percentage,
  });

  factory StudentPerformanceExams.fromJson(Map<String, dynamic> json) {
    return StudentPerformanceExams(
      totalMarksObtained: json['totalMarksObtained'] ?? 0,
      totalMaximumMarks: json['totalMaximumMarks'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}
