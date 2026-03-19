import 'dart:developer';

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
  });

  factory ClassRoom.fromJson(Map<String, dynamic> json) => ClassRoom(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    schoolId: json['schoolId'] ?? '',
    description: json['description'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'schoolId': schoolId,
    'description': description,
  };
}

class Section {
  final String id;
  final String classId;
  final String name; // e.g., "A"

  Section({required this.id, required this.classId, required this.name});

  factory Section.fromJson(Map<String, dynamic> json) => Section(
    id: json['id'] ?? json['_id'] ?? '',
    classId: json['classId'] ?? '',
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'classId': classId, 'name': name};
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
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'] ?? json['_id'] ?? '',
    name: json['name'] ?? '',
    code: json['code'] ?? '',
    classId: json['classId'] ?? '',
    schoolId: json['schoolId'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'classId': classId,
    'schoolId': schoolId,
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

class Homework {
  final String id;
  final String teacherId;
  final String classId;
  final String sectionId;
  final String subjectId;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime createdAt;

  Homework({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.createdAt,
  });

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
    id: json['id'],
    teacherId: json['teacherId'],
    classId: json['classId'],
    sectionId: json['sectionId'],
    subjectId: json['subjectId'],
    title: json['title'],
    description: json['description'],
    dueDate: DateTime.parse(json['dueDate']),
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'teacherId': teacherId,
    'classId': classId,
    'sectionId': sectionId,
    'subjectId': subjectId,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };
}

class Notice {
  final String title;
  final String content;
  final String? classId; // For local UI logic
  final String? schoolId;
  final String? audience;
  final String? postedBy;
  final bool isImportant;

  Notice({
    required this.title,
    required this.content,
    this.classId,
    this.schoolId,
    this.audience,
    this.postedBy,
    this.isImportant = false,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    classId: json['classId'],
    schoolId: json['schoolId'],
    audience: json['audience'],
    postedBy: json['postedBy'],
    isImportant: json['isImportant'] ?? json['isImportent'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'classId': classId,
    'schoolId': schoolId,
    'audience': audience,
    'postedBy': postedBy,
    'isImportant': isImportant,
    'isImportent': isImportant, // API expects this spelling in the example
  };
}

class RoutineEntry {
  final String? id;
  final String? classId;
  final String? schoolId;
  final String day; // Monday, Tuesday, etc.
  final String startTime;
  final String endTime;
  final String subjectId;
  final String teacherId;
  final String? roomNumber;

  RoutineEntry({
    this.id,
    this.classId,
    this.schoolId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subjectId,
    required this.teacherId,
    this.roomNumber,
  });

  factory RoutineEntry.fromJson(Map<String, dynamic> json) {
    log('Parsing RoutineEntry from JSON: $json');
    return RoutineEntry(
      id: json['id'] ?? json['_id'],
      classId: json['classId'],
      schoolId: json['schoolId'],
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      subjectId: json['subjectId'] ?? '',
      teacherId: json['teacherId'] ?? '',
      roomNumber: json['roomNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      if (id != null) 'id': id,
      'classId': classId,
      'schoolId': schoolId,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'subjectId': subjectId,
      'teacherId': teacherId,
      if (roomNumber != null) 'roomNumber': roomNumber,
    };
    log('Serializing RoutineEntry to JSON: $data');
    return data;
  }
}

class Exam {
  final String id;
  final String name; // e.g., "Final Exam 2024"
  final String subjectId;
  final String teacherId; // Examiner
  final String classId;
  final String sectionId;
  final DateTime dateTime;
  final bool isPublished;

  Exam({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.teacherId,
    required this.classId,
    required this.sectionId,
    required this.dateTime,
    this.isPublished = false,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    // Support both API snake_case and legacy camelCase keys
    final String id =
        json['id'] ?? json['_id'] ?? json['uid'] ?? '';
    final String name =
        json['exam_name'] ?? json['name'] ?? '';
    final String classId =
        json['class_uid'] ?? json['classId'] ?? '';
    final String subjectId =
        json['subject_uid'] ?? json['subjectId'] ?? '';
    final String teacherId =
        json['examiner_uid'] ?? json['teacherId'] ?? '';
    final String sectionId = json['sectionId'] ?? '';

    // API may send just a date string "2025-06-15" or a full ISO dateTime
    DateTime dateTime;
    final raw = json['date'] ?? json['dateTime'];
    if (raw != null) {
      dateTime = DateTime.tryParse(raw.toString()) ?? DateTime.now();
    } else {
      dateTime = DateTime.now();
    }

    return Exam(
      id: id,
      name: name,
      subjectId: subjectId,
      teacherId: teacherId,
      classId: classId,
      sectionId: sectionId,
      dateTime: dateTime,
      isPublished: json['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subjectId': subjectId,
    'teacherId': teacherId,
    'classId': classId,
    'sectionId': sectionId,
    'dateTime': dateTime.toIso8601String(),
    'isPublished': isPublished,
  };
}

class Result {
  final String id;
  final String examId;
  final String studentId;
  final double marksObtained;
  final double totalMarks;
  final String remarks;

  Result({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.marksObtained,
    required this.totalMarks,
    required this.remarks,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json['id'],
    examId: json['examId'],
    studentId: json['studentId'],
    marksObtained: (json['marksObtained'] as num).toDouble(),
    totalMarks: (json['totalMarks'] as num).toDouble(),
    remarks: json['remarks'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'examId': examId,
    'studentId': studentId,
    'marksObtained': marksObtained,
    'totalMarks': totalMarks,
    'remarks': remarks,
  };
}
