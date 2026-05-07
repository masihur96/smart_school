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

  AttendStudent({
    required this.date,
    required this.totalStudents,
    required this.recorded,
    required this.present,
    required this.absent,
    required this.leave,
    required this.attendanceRate,
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
