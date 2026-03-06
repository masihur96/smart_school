class ClassRoom {
  final String id;
  final String name; // e.g., "Class 10"

  ClassRoom({required this.id, required this.name});

  factory ClassRoom.fromJson(Map<String, dynamic> json) =>
      ClassRoom(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Section {
  final String id;
  final String classId;
  final String name; // e.g., "A"

  Section({required this.id, required this.classId, required this.name});

  factory Section.fromJson(Map<String, dynamic> json) =>
      Section(id: json['id'], classId: json['classId'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'classId': classId, 'name': name};
}

class Subject {
  final String id;
  final String name;

  Subject({required this.id, required this.name});

  factory Subject.fromJson(Map<String, dynamic> json) =>
      Subject(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Attendance {
  final String id;
  final String studentId;
  final DateTime date;
  final bool isPresent;
  final String takenBy; // teacher id

  Attendance({
    required this.id,
    required this.studentId,
    required this.date,
    required this.isPresent,
    required this.takenBy,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'],
        studentId: json['studentId'],
        date: DateTime.parse(json['date']),
        isPresent: json['isPresent'],
        takenBy: json['takenBy'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'date': date.toIso8601String(),
        'isPresent': isPresent,
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
  final String id;
  final String title;
  final String content;
  final String? classId; // Null means global
  final bool isImportant;
  final DateTime date;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    this.classId,
    this.isImportant = false,
    required this.date,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        classId: json['classId'],
        isImportant: json['isImportant'] ?? false,
        date: DateTime.parse(json['date']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'classId': classId,
        'isImportant': isImportant,
        'date': date.toIso8601String(),
      };
}

class RoutineEntry {
  final String day; // Monday, Tuesday, etc.
  final String startTime;
  final String endTime;
  final String subjectId;
  final String teacherId;

  RoutineEntry({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subjectId,
    required this.teacherId,
  });

  factory RoutineEntry.fromJson(Map<String, dynamic> json) => RoutineEntry(
        day: json['day'],
        startTime: json['startTime'],
        endTime: json['endTime'],
        subjectId: json['subjectId'],
        teacherId: json['teacherId'],
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'subjectId': subjectId,
        'teacherId': teacherId,
      };
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

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'],
        name: json['name'],
        subjectId: json['subjectId'],
        teacherId: json['teacherId'],
        classId: json['classId'],
        sectionId: json['sectionId'],
        dateTime: DateTime.parse(json['dateTime']),
        isPublished: json['isPublished'] ?? false,
      );

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
