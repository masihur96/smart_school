import 'dart:developer';

class School {
  final String id;
  final String schoolId;
  final String name;
  final String address;
  final String phone;
  final String email;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  School({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory School.fromJson(Map<String, dynamic> json) => School(
        id: json['id'] ?? '',
        schoolId: json['schoolId'] ?? '',
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        isActive: json['isActive'] ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
        deletedAt: json['deletedAt'] != null
            ? DateTime.tryParse(json['deletedAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'schoolId': schoolId,
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}

class ClassRoom {
  final String id;
  final String name; // e.g., "Class 10"
  final String schoolId;
  final String description;

  ClassRoom({
    required this.id,
    required this.name,
    this.schoolId = '',
    this.description = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  final DateTime? deletedAt;

  factory ClassRoom.fromJson(Map<String, dynamic> json) => ClassRoom(
    id: json['id'] ?? json['_id'] ?? '',
    name: json['name'] ?? '',
    schoolId: json['schoolId'] ?? '',
    description: json['description'] ?? '',
    deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'schoolId': schoolId,
    'description': description,
    'deletedAt': deletedAt?.toIso8601String(),
  };
}

class Section {
  final String id;
  final String classId;
  final String name; // e.g., "A"
  final DateTime? deletedAt;

  Section({required this.id, required this.classId, required this.name, this.deletedAt});

  bool get isDeleted => deletedAt != null;

  factory Section.fromJson(Map<String, dynamic> json) => Section(
    id: json['id'] ?? json['_id'] ?? '',
    classId: json['classId'] ?? '',
    name: json['name'] ?? '',
    deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {'id': id, 'classId': classId, 'name': name, 'deletedAt': deletedAt?.toIso8601String()};
}

class Subject {
  final String id;
  final String name;
  final String code;
  final String classId;
  final String schoolId;

  Subject({
    required this.id,
    required this.name,
    this.code = '',
    this.classId = '',
    this.schoolId = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  final DateTime? deletedAt;

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'] ?? json['_id'] ?? '',
    name: json['name'] ?? '',
    code: json['code'] ?? '',
    classId: json['classId'] ?? '',
    schoolId: json['schoolId'] ?? '',
    deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'classId': classId,
    'schoolId': schoolId,
    'deletedAt': deletedAt?.toIso8601String(),
  };
}

enum AttendanceStatus { present, absent, leave }

class Attendance {
  final String id;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String takenBy; // teacher id

  Attendance({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    required this.takenBy,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
    id: json['id'],
    studentId: json['studentId'],
    date: DateTime.parse(json['date']),
    status: AttendanceStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => AttendanceStatus.absent,
    ),
    takenBy: json['takenBy'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'date': date.toIso8601String(),
    'status': status.name,
    'takenBy': takenBy,
  };
}

class AttendanceOverviewData {
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final int totalPresent;
  final int totalAbsent;
  final int totalLeave;
  final int totalRecords;
  final double attendancePercentage;

  AttendanceOverviewData({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLeave,
    required this.totalRecords,
    required this.attendancePercentage,
  });

  factory AttendanceOverviewData.fromJson(Map<String, dynamic> json) =>
      AttendanceOverviewData(
        classId: json['classId'] ?? '',
        className: json['className'] ?? '',
        sectionId: json['sectionId'] ?? '',
        sectionName: json['sectionName'] ?? '',
        totalPresent: json['totalPresent'] ?? 0,
        totalAbsent: json['totalAbsent'] ?? 0,
        totalLeave: json['totalLeave'] ?? 0,
        totalRecords: json['totalRecords'] ?? 0,
        attendancePercentage: (json['attendancePercentage'] as num).toDouble(),
      );
}

class AttendanceOverview {
  final int year;
  final int month;
  final List<AttendanceOverviewData> data;
  final int grandTotalPresent;
  final int grandTotalAbsent;
  final int grandTotalLeave;
  final double overallAttendancePercentage;

  AttendanceOverview({
    required this.year,
    required this.month,
    required this.data,
    required this.grandTotalPresent,
    required this.grandTotalAbsent,
    required this.grandTotalLeave,
    required this.overallAttendancePercentage,
  });

  factory AttendanceOverview.fromJson(Map<String, dynamic> json) =>
      AttendanceOverview(
        year: json['year'] ?? 0,
        month: json['month'] ?? 0,
        data: (json['data'] as List? ?? [])
            .map((e) => AttendanceOverviewData.fromJson(e))
            .toList(),
        grandTotalPresent: json['grandTotalPresent'] ?? 0,
        grandTotalAbsent: json['grandTotalAbsent'] ?? 0,
        grandTotalLeave: json['grandTotalLeave'] ?? 0,
        overallAttendancePercentage:
            (json['overallAttendancePercentage'] as num).toDouble(),
      );
}

class Homework {
  final String id;
  final String teacherId;
  final String classId;
  final String sectionId;
  final String subjectId;
  final String title;
  final String description;
  final String schoolId;
  final DateTime dueDate;
  final DateTime createdAt;
  final List<StudentHomework> studentHomeworks;
  final ClassRoom? classInfo;
  final Subject? subjectInfo;
  final Section? sectionInfo;

  Homework({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.schoolId,
    required this.dueDate,
    required this.createdAt,
    this.studentHomeworks = const [],
    this.classInfo,
    this.subjectInfo,
    this.sectionInfo,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  final DateTime? deletedAt;

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
    id: json['id'] ?? '',
    teacherId: json['teacherId'] ?? '',
    classId: json['classId'] ?? '',
    sectionId: json['sectionId'] ?? '',
    subjectId: json['subjectId'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    schoolId: json['schoolId'] ?? '',
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    studentHomeworks: (json['studentHomeworks'] as List? ?? [])
        .map((e) => StudentHomework.fromJson(e))
        .toList(),
    classInfo: json['classInfo'] != null ? ClassRoom.fromJson(json['classInfo']) : null,
    subjectInfo: json['subjectInfo'] != null ? Subject.fromJson(json['subjectInfo']) : null,
    sectionInfo: json['sectionInfo'] != null ? Section.fromJson(json['sectionInfo']) : null,
    deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'teacherId': teacherId,
    'classId': classId,
    'sectionId': sectionId,
    'subjectId': subjectId,
    'title': title,
    'description': description,
    'schoolId': schoolId,
    'dueDate': dueDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'studentHomeworks': studentHomeworks.map((e) => e.toJson()).toList(),
    if (classInfo != null) 'classInfo': classInfo!.toJson(),
    if (subjectInfo != null) 'subjectInfo': subjectInfo!.toJson(),
    if (sectionInfo != null) 'sectionInfo': sectionInfo!.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };
}

class StudentHomework {
  final String id;
  final String homeworkId;
  final String studentId;
  final String status;
  final String? comment;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StudentSummary? student;
  final Homework? homework;

  StudentHomework({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    required this.status,
    this.comment,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.student,
    this.homework,
  });

  factory StudentHomework.fromJson(Map<String, dynamic> json) => StudentHomework(
    id: json['id'] ?? '',
    homeworkId: json['homeworkId'] ?? '',
    studentId: json['studentId'] ?? '',
    status: json['status'] ?? 'pending',
    comment: json['comment'],
    updatedBy: json['updatedBy'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    student: json['student'] != null ? StudentSummary.fromJson(json['student']) : null,
    homework: json['homework'] != null ? Homework.fromJson(json['homework']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'homeworkId': homeworkId,
    'studentId': studentId,
    'status': status,
    'comment': comment,
    'updatedBy': updatedBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (student != null) 'student': student!.toJson(),
    if (homework != null) 'homework': homework!.toJson(),
  };
}

class StudentSummary {
  final String id;
  final String name;
  final String? rollNumber;
  final String? email;
  final String? phone;

  StudentSummary({
    required this.id,
    required this.name,
    this.rollNumber,
    this.email,
    this.phone,
  });

  factory StudentSummary.fromJson(Map<String, dynamic> json) => StudentSummary(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    rollNumber: json['rollNumber'],
    email: json['email'],
    phone: json['phone'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rollNumber': rollNumber,
    'email': email,
    'phone': phone,
  };
}

class Notice {
  final String? id;
  final String title;
  final String content;
  final String? classId; // For local UI logic only
  final String? schoolId;
  final String? targetAudience; // API field: "Students", "Teachers", "Parents", "All"
  final String? postedBy; // Name of poster, e.g. "Principal"
  final bool isImportant;

  Notice({
    this.id,
    required this.title,
    required this.content,
    this.classId,
    this.schoolId,
    this.targetAudience,
    this.postedBy,
    this.isImportant = false,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  final DateTime? deletedAt;

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    id: json['id'] ?? json['_id'],
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    classId: json['classId'],
    schoolId: json['schoolId'],
    targetAudience: json['targetAudience'] ?? json['audience'],
    postedBy: json['postedBy'],
    isImportant: json['isImportant'] ?? json['isImportent'] ?? false,
    deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'targetAudience': targetAudience ?? 'All',
    'schoolId': schoolId,
    'postedBy': postedBy,
    'isImportent': isImportant, // API uses this spelling
    'deletedAt': deletedAt?.toIso8601String(),
  };

  Notice copyWith({
    String? id,
    String? title,
    String? content,
    String? classId,
    String? schoolId,
    String? targetAudience,
    String? postedBy,
    bool? isImportant,
  }) => Notice(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    classId: classId ?? this.classId,
    schoolId: schoolId ?? this.schoolId,
    targetAudience: targetAudience ?? this.targetAudience,
    postedBy: postedBy ?? this.postedBy,
    isImportant: isImportant ?? this.isImportant,
  );
}

class RoutineEntry {
  final String? id;
  final String? classId;
  final String? sectionId;
  final String? schoolId;
  final String day; // Monday, Tuesday, etc.
  final String startTime;
  final String endTime;
  final String subjectId;
  final String teacherId;
  final String? roomNumber;
  final ClassRoom? classEntity;
  final Subject? subjectEntity;
  final Section? sectionEntity;
  final Teacher? teacherEntity;

  RoutineEntry({
    this.id,
    this.classId,
    this.sectionId,
    this.schoolId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subjectId,
    required this.teacherId,
    this.roomNumber,
    this.classEntity,
    this.subjectEntity,
    this.sectionEntity,
    this.teacherEntity,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  final DateTime? deletedAt;

  factory RoutineEntry.fromJson(Map<String, dynamic> json) {
    log('Parsing RoutineEntry from JSON: $json');
    return RoutineEntry(
      id: json['id'] ?? json['_id'],
      classId: json['classId'],
      sectionId: json['sectionId'],
      schoolId: json['schoolId'],
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      subjectId: json['subjectId'] ?? '',
      teacherId: json['teacherId'] ?? '',
      roomNumber: json['roomNumber'],
      classEntity: json['classEntity'] != null ? ClassRoom.fromJson(json['classEntity']) : null,
      subjectEntity: json['subjectEntity'] != null ? Subject.fromJson(json['subjectEntity']) : null,
      sectionEntity: json['sectionEntity'] != null ? Section.fromJson(json['sectionEntity']) : null,
      teacherEntity: json['teacherEntity'] != null ? Teacher.fromJson(json['teacherEntity']) : null,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      if (id != null) 'id': id,
      'classId': classId,
      'sectionId': sectionId,
      'schoolId': schoolId,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'subjectId': subjectId,
      'teacherId': teacherId,
      if (roomNumber != null) 'roomNumber': roomNumber,
      'deletedAt': deletedAt?.toIso8601String(),
    };
    log('Serializing RoutineEntry to JSON: $data');
    return data;
  }
}

class ExamAssignment {
  final String id;
  final String examId;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String examinerId;
  final String examinerName;
  final DateTime date;
  final String? syllabus;

  ExamAssignment({
    required this.id,
    required this.examId,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.examinerId,
    required this.examinerName,
    required this.date,
    this.syllabus,
  });

  factory ExamAssignment.fromJson(Map<String, dynamic> json) {
    return ExamAssignment(
      id: json['id'] ?? '',
      examId: json['examId'] ?? '',
      classId: json['class']?['uuid'] ?? '',
      className: json['class']?['name'] ?? '',
      subjectId: json['subject']?['uuid'] ?? '',
      subjectName: json['subject']?['name'] ?? '',
      examinerId: json['examiner']?['uuid'] ?? '',
      examinerName: json['examiner']?['name'] ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      syllabus: json['syllabus'],
    );
  }
}

class Exam {
  final String id;
  final String name; // e.g., "Final Exam 2024"
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ExamAssignment> assignments;
  final bool isPublished;

  Exam({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.assignments = const [],
    this.isPublished = false,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  final DateTime? deletedAt;

  factory Exam.fromJson(Map<String, dynamic> json) {
    // Support both API snake_case and legacy camelCase keys
    final String id =
        json['id'] ?? json['_id'] ?? json['uid'] ?? '';
    final String name =
        json['exam_name'] ?? json['name'] ?? '';
    final String? description = json['description'];

    DateTime? startDate;
    if (json['start_date'] != null) {
      startDate = DateTime.tryParse(json['start_date'].toString());
    }

    DateTime? endDate;
    if (json['end_date'] != null) {
      endDate = DateTime.tryParse(json['end_date'].toString());
    }

    List<ExamAssignment> assignments = [];
    if (json['assignments'] != null && json['assignments'] is List) {
      assignments = (json['assignments'] as List)
          .map((a) => ExamAssignment.fromJson(a))
          .toList();
    }

    return Exam(
      id: id,
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      assignments: assignments,
      isPublished: (json['isPublished'] ?? json['is_published']) ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exam_name': name,
    'description': description,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'isPublished': isPublished,
    'deletedAt': deletedAt?.toIso8601String(),
  };
}

class Result {
  final String id;
  final String examId;
  final String studentId;
  final double marksObtained;
  final double totalMarks;
  final String remarks;
  final Exam? exam;
  final Subject? subject;
  final Teacher? teacher;

  Result({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.marksObtained,
    required this.totalMarks,
    required this.remarks,
    this.exam,
    this.subject,
    this.teacher,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    double parsedMarksObtained = 0.0;
    if (json['marksObtained'] != null) {
      if (json['marksObtained'] is String) {
        parsedMarksObtained = double.tryParse(json['marksObtained']) ?? 0.0;
      } else if (json['marksObtained'] is num) {
        parsedMarksObtained = (json['marksObtained'] as num).toDouble();
      }
    }

    double parsedTotalMarks = 0.0;
    if (json['totalMarks'] != null) {
      if (json['totalMarks'] is String) {
        parsedTotalMarks = double.tryParse(json['totalMarks']) ?? 0.0;
      } else if (json['totalMarks'] is num) {
        parsedTotalMarks = (json['totalMarks'] as num).toDouble();
      }
    }

    return Result(
      id: json['id'] ?? '',
      examId: json['examId'] ?? '',
      studentId: json['studentId'] ?? '',
      marksObtained: parsedMarksObtained,
      totalMarks: parsedTotalMarks,
      remarks: json['remarks'] ?? '',
      exam: json['exam'] != null ? Exam.fromJson(json['exam']) : null,
      subject: json['subject'] != null ? Subject.fromJson(json['subject']) : null,
      teacher: json['teacher'] != null ? Teacher.fromJson(json['teacher']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'examId': examId,
    'studentId': studentId,
    'marksObtained': marksObtained,
    'totalMarks': totalMarks,
    'remarks': remarks,
  };
}

class TeacherAssignmentClass {
  final String uuid;
  final String name;

  TeacherAssignmentClass({required this.uuid, required this.name});

  factory TeacherAssignmentClass.fromJson(Map<String, dynamic> json) =>
      TeacherAssignmentClass(
        uuid: json['uuid'] ?? '',
        name: json['name'] ?? '',
      );
}

class TeacherAssignmentStudent {
  final String id;
  final String name;
  final String rollNumber;

  TeacherAssignmentStudent({
    required this.id,
    required this.name,
    required this.rollNumber,
  });

  factory TeacherAssignmentStudent.fromJson(Map<String, dynamic> json) =>
      TeacherAssignmentStudent(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        rollNumber: json['rollNumber'] ?? '',
      );
}

class TeacherAssignmentSubject {
  final String uuid;
  final String name;
  final double? existingMark;

  TeacherAssignmentSubject({
    required this.uuid,
    required this.name,
    this.existingMark,
  });

  factory TeacherAssignmentSubject.fromJson(Map<String, dynamic> json) {
    final subjectObj = json['subject'] as Map<String, dynamic>?;
    
    double? parsedMark;
    if (json['existingMark'] != null) {
      final existing = json['existingMark'];
      if (existing is Map) {
        final markStr = existing['marksObtained'];
        if (markStr != null) {
          parsedMark = double.tryParse(markStr.toString());
        }
      } else if (existing is num) {
        parsedMark = existing.toDouble();
      } else if (existing is String) {
        parsedMark = double.tryParse(existing);
      }
    }

    return TeacherAssignmentSubject(
      uuid: subjectObj?['uuid'] ?? '',
      name: subjectObj?['name'] ?? '',
      existingMark: parsedMark,
    );
  }
}

class Teacher {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? designation;

  Teacher({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.designation,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  final DateTime? deletedAt;

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'],
        phone: json['phone'],
        designation: json['designation'],
        deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'designation': designation,
        'deletedAt': deletedAt?.toIso8601String(),
      };
}

class TeacherSelfAttendance {
  final String id;
  final String teacherId;
  final String date;
  final String time;
  final String lat;
  final String lon;
  final double distanceFromCenter;
  final String status;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? startTime;
  final String? endTime;
  final Teacher? teacher;

  TeacherSelfAttendance({
    required this.id,
    required this.teacherId,
    required this.date,
    required this.time,
    required this.lat,
    required this.lon,
    required this.distanceFromCenter,
    required this.status,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.startTime,
    this.endTime,
    this.teacher,
  });

  factory TeacherSelfAttendance.fromJson(Map<String, dynamic> json) =>
      TeacherSelfAttendance(
        id: json['id'] ?? '',
        teacherId: json['teacherId'] ?? '',
        date: json['date'] ?? '',
        time: json['time'] ?? '',
        lat: json['lat']?.toString() ?? '',
        lon: json['lon']?.toString() ?? '',
        distanceFromCenter:
            (json['distanceFromCenter'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] ?? '',
        schoolId: json['schoolId'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
        startTime: json['startTime'],
        endTime: json['endTime'],
        teacher: json['teacher'] != null ? Teacher.fromJson(json['teacher']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacherId': teacherId,
        'date': date,
        'time': time,
        'lat': lat,
        'lon': lon,
        'distanceFromCenter': distanceFromCenter,
        'status': status,
        'schoolId': schoolId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (teacher != null) 'teacher': teacher!.toJson(),
      };
}

class Marquee {
  final String text;
  final String type;
  final String schoolId;

  Marquee({required this.text, required this.type, required this.schoolId});

  factory Marquee.fromJson(Map<String, dynamic> json) => Marquee(
    text: json['text'] ?? '',
    type: json['type'] ?? '',
    schoolId: json['schoolId'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'text': text,
    'type': type,
    'schoolId': schoolId,
  };
}
