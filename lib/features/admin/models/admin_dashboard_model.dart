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
              ?.map((e) => RecentHomework.fromJson(e))
              .toList() ??
          [],
      recentNotice: (json['recentNotice'] as List<dynamic>?)
              ?.map((e) => RecentNotice.fromJson(e))
              .toList() ??
          [],
      currentExam: (json['currentExam'] as List<dynamic>?)
              ?.map((e) => CurrentExam.fromJson(e))
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
      date: json['date'] ?? '',
      totalTeachers: json['totalTeachers'] ?? 0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
      recentRecords: (json['recentRecords'] as List<dynamic>?)
              ?.map((e) => TeacherRecentRecord.fromJson(e))
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
  final double attendanceRate;
  final List<StudentAttendanceRecord> data;

  AttendStudent({
    required this.date,
    required this.totalStudents,
    required this.recorded,
    required this.present,
    required this.absent,
    required this.leave,
    required this.attendanceRate,
    required this.data,
  });

  factory AttendStudent.fromJson(Map<String, dynamic> json) {
    return AttendStudent(
      date: json['date'] ?? '',
      totalStudents: json['totalStudents'] ?? 0,
      recorded: json['recorded'] ?? 0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      leave: json['leave'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => StudentAttendanceRecord.fromJson(e))
              .toList() ??
          [],
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
    this.subjectId,
    this.subjectName,
  });

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRecord(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['student']?['name'] ?? 'Unknown',
      rollNumber: json['student']?['rollNumber'] ?? '',
      designation: json['student']?['designation'] ?? '',
      status: json['status'] ?? '',
      date: json['date'] ?? '',
      className: json['class']?['name'] ?? '',
      subjectId: json['subjectId'],
      subjectName: json['subject']?['name'],
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

  RecentHomework({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.className,
    required this.subjectName,
    required this.sectionName,
  });

  factory RecentHomework.fromJson(Map<String, dynamic> json) {
    return RecentHomework(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] ?? '',
      className: json['classInfo']?['name'] ?? '',
      subjectName: json['subjectInfo']?['name'] ?? '',
      sectionName: json['sectionInfo']?['name'] ?? '',
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

  RecentNotice({
    required this.id,
    required this.title,
    required this.content,
    required this.targetAudience,
    required this.isImportent,
    required this.postedBy,
    required this.createdAt,
  });

  factory RecentNotice.fromJson(Map<String, dynamic> json) {
    return RecentNotice(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      targetAudience: json['targetAudience'] ?? '',
      isImportent: json['isImportent'] ?? false,
      postedBy: json['postedBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
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

  CurrentExam({
    required this.id,
    required this.examName,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isPublished,
  });

  factory CurrentExam.fromJson(Map<String, dynamic> json) {
    return CurrentExam(
      id: json['id'] ?? '',
      examName: json['exam_name'] ?? '',
      description: json['description'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      isPublished: json['is_published'] ?? false,
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
      id: json['id'] ?? '',
      teacherName: json['teacher']?['name'] ?? 'Unknown',
      designation: json['teacher']?['designation'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'],
      status: json['status'] ?? '',
      lat: json['lat'] ?? '',
      lon: json['lon'] ?? '',
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
  final String designation;
  final PerformanceAttendance attendance;
  final PerformanceHomework homework;

  TeacherPerformance({
    required this.teacherId,
    required this.name,
    required this.designation,
    required this.attendance,
    required this.homework,
  });

  factory TeacherPerformance.fromJson(Map<String, dynamic> json) {
    return TeacherPerformance(
      teacherId: json['teacherId'] ?? '',
      name: json['name'] ?? '',
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
