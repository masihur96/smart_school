import 'user_model.dart';

class Teacher {
  final String userId;
  final List<AssignedSubject> assignedSubjects;
  final User? user;

  Teacher({required this.userId, required this.assignedSubjects, this.user});

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      userId: json['userId'],
      assignedSubjects: (json['assignedSubjects'] as List)
          .map((e) => AssignedSubject.fromJson(e))
          .toList(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'assignedSubjects': assignedSubjects.map((e) => e.toJson()).toList(),
      if (user != null) 'user': user!.toJson(),
    };
  }
}

class AssignedSubject {
  final String classId;
  final String sectionId;
  final String subjectId;

  AssignedSubject({
    required this.classId,
    required this.sectionId,
    required this.subjectId,
  });

  factory AssignedSubject.fromJson(Map<String, dynamic> json) {
    return AssignedSubject(
      classId: json['classId'],
      sectionId: json['sectionId'],
      subjectId: json['subjectId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'classId': classId, 'sectionId': sectionId, 'subjectId': subjectId};
  }
}
