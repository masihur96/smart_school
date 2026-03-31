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
  final String schoolId;
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
    required this.schoolId,
    required this.dueDate,
    required this.createdAt,
  });

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
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    id: json['id'] ?? json['_id'],
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    classId: json['classId'],
    schoolId: json['schoolId'],
    targetAudience: json['targetAudience'] ?? json['audience'],
    postedBy: json['postedBy'],
    isImportant: json['isImportant'] ?? json['isImportent'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'targetAudience': targetAudience ?? 'All',
    'schoolId': schoolId,
    'postedBy': postedBy,
    'isImportent': isImportant, // API uses this spelling
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
  final String? schoolId;
  final String day; // Monday, Tuesday, etc.
  final String startTime;
  final String endTime;
  final String subjectId;
  final String teacherId;
  final String? roomNumber;
  final ClassRoom? classEntity;
  final Subject? subjectEntity;

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
    this.classEntity,
    this.subjectEntity,
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
      classEntity: json['classEntity'] != null ? ClassRoom.fromJson(json['classEntity']) : null,
      subjectEntity: json['subjectEntity'] != null ? Subject.fromJson(json['subjectEntity']) : null,
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
  });

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
      isPublished: json['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exam_name': name,
    'description': description,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
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
