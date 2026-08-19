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

  factory MonthlyAttendanceOverview.fromJson(dynamic json) {
    if (json == null) {
      return MonthlyAttendanceOverview(year: DateTime.now().year, data: []);
    }

    if (json is List) {
      final list = json
          .map((e) => MonthlyAttendanceData.fromJson(e))
          .where((e) => e.month >= 1 && e.month <= 12)
          .toList()
        ..sort((a, b) => a.month.compareTo(b.month));
      return MonthlyAttendanceOverview(
        year: DateTime.now().year,
        data: list,
      );
    }

    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      int parsedYear = DateTime.now().year;
      final rawYear = map['year'] ?? map['currentYear'];
      if (rawYear is int) {
        parsedYear = rawYear;
      } else if (rawYear != null) {
        parsedYear = int.tryParse(rawYear.toString()) ?? DateTime.now().year;
      }

      dynamic rawList = map['data'] ??
          map['overview'] ??
          map['monthlyData'] ??
          map['months'] ??
          map['list'];

      List<MonthlyAttendanceData> list = [];
      if (rawList is List) {
        list = rawList
            .map((e) => MonthlyAttendanceData.fromJson(e))
            .where((e) => e.month >= 1 && e.month <= 12)
            .toList()
          ..sort((a, b) => a.month.compareTo(b.month));
      } else if (rawList is Map) {
        list = rawList.entries.map((entry) {
          if (entry.value is Map) {
            final entryMap = Map<String, dynamic>.from(entry.value as Map);
            entryMap['month'] ??= entry.key;
            return MonthlyAttendanceData.fromJson(entryMap);
          }
          return MonthlyAttendanceData.fromJson({'month': entry.key});
        }).where((e) => e.month >= 1 && e.month <= 12).toList()
          ..sort((a, b) => a.month.compareTo(b.month));
      }

      return MonthlyAttendanceOverview(
        year: parsedYear,
        data: list,
      );
    }

    return MonthlyAttendanceOverview(year: DateTime.now().year, data: []);
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

  String get monthName {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Month $month';
  }

  String get fullMonthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Month $month';
  }

  factory MonthlyAttendanceData.fromJson(dynamic json) {
    if (json is! Map) {
      return MonthlyAttendanceData(
        month: 0,
        totalPresent: 0,
        totalAbsent: 0,
        totalLeave: 0,
        totalLate: 0,
        attendancePercentage: 0.0,
      );
    }

    final map = Map<String, dynamic>.from(json);

    // Parse month (handles int, strings like "05", "5", "May", "may", etc.)
    int parsedMonth = 0;
    final rawMonth = map['month'] ??
        map['monthNumber'] ??
        map['month_number'] ??
        map['monthName'] ??
        map['month_name'] ??
        map['name'];

    if (rawMonth is int) {
      parsedMonth = rawMonth;
    } else if (rawMonth is num) {
      parsedMonth = rawMonth.toInt();
    } else if (rawMonth != null) {
      final s = rawMonth.toString().trim();
      final directInt = int.tryParse(s);
      if (directInt != null) {
        parsedMonth = directInt;
      } else {
        const monthNames = {
          'jan': 1, 'january': 1, '01': 1, '1': 1,
          'feb': 2, 'february': 2, '02': 2, '2': 2,
          'mar': 3, 'march': 3, '03': 3, '3': 3,
          'apr': 4, 'april': 4, '04': 4, '4': 4,
          'may': 5, '05': 5, '5': 5,
          'jun': 6, 'june': 6, '06': 6, '6': 6,
          'jul': 7, 'july': 7, '07': 7, '7': 7,
          'aug': 8, 'august': 8, '08': 8, '8': 8,
          'sep': 9, 'september': 9, '09': 9, '9': 9,
          'oct': 10, 'october': 10, '10': 10,
          'nov': 11, 'november': 11, '11': 11,
          'dec': 12, 'december': 12, '12': 12,
        };
        parsedMonth = monthNames[s.toLowerCase()] ?? 0;
      }
    }

    // Parse percentage
    double parsedPercentage = 0.0;
    final rawPercentage = map['attendancePercentage'] ??
        map['percentage'] ??
        map['attendanceRate'] ??
        map['rate'] ??
        map['presentPercentage'];
    if (rawPercentage is num) {
      parsedPercentage = rawPercentage.toDouble();
    } else if (rawPercentage != null) {
      parsedPercentage = double.tryParse(rawPercentage.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val != null) return int.tryParse(val.toString()) ?? 0;
      return 0;
    }

    final totalPresent = parseInt(
      map['totalPresent'] ?? map['present'] ?? map['total_present'],
    );
    final totalAbsent = parseInt(
      map['totalAbsent'] ?? map['absent'] ?? map['total_absent'],
    );
    final totalLeave = parseInt(
      map['totalLeave'] ?? map['leave'] ?? map['total_leave'],
    );
    final totalLate = parseInt(
      map['totalLate'] ?? map['late'] ?? map['total_late'],
    );

    // If attendancePercentage wasn't provided or 0, calculate if totalPresent and totalAbsent exist
    if (parsedPercentage == 0.0 && (totalPresent > 0 || totalAbsent > 0)) {
      final totalRecords = totalPresent + totalAbsent + totalLeave;
      if (totalRecords > 0) {
        parsedPercentage = (totalPresent / totalRecords) * 100;
      }
    }

    return MonthlyAttendanceData(
      month: parsedMonth,
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      totalLeave: totalLeave,
      totalLate: totalLate,
      attendancePercentage: parsedPercentage,
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

class StudentPerformance {
  final String studentId;
  final String name;
  final String? rollNumber;
  final PerformanceClass? classInfo;
  final PerformanceSection? section;
  final PerformanceAttendance attendance;
  final StudentPerformanceHomework homework;
  final StudentPerformanceExams exams;

  StudentPerformance({
    required this.studentId,
    required this.name,
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
