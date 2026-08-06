class OnlineClass {
  final String id;
  final String title;
  final String description;
  final String meetLink;
  final DateTime scheduledTime;
  final String teacherId;
  final String teacherName;
  final String? classId;
  final String? sectionId;
  final String? subjectId;
  final DateTime createdAt;

  OnlineClass({
    required this.id,
    required this.title,
    required this.description,
    required this.meetLink,
    required this.scheduledTime,
    required this.teacherId,
    required this.teacherName,
    this.classId,
    this.sectionId,
    this.subjectId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory OnlineClass.fromJson(Map<String, dynamic> json) => OnlineClass(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        meetLink: json['meetLink'] ?? '',
        scheduledTime: json['scheduledTime'] != null
            ? DateTime.parse(json['scheduledTime'])
            : DateTime.now(),
        teacherId: json['teacherId'] ?? '',
        teacherName: json['teacherName'] ?? '',
        classId: json['classId'],
        sectionId: json['sectionId'],
        subjectId: json['subjectId'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'meetLink': meetLink,
        'scheduledTime': scheduledTime.toIso8601String(),
        'teacherId': teacherId,
        'teacherName': teacherName,
        'classId': classId,
        'sectionId': sectionId,
        'subjectId': subjectId,
        'createdAt': createdAt.toIso8601String(),
      };
}
