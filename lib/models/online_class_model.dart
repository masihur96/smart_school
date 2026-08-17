class OnlineClass {
  final String id;
  final String title;
  final String description;
  final String meetLink;
  final DateTime scheduledTime;
  final String teacherId;
  final String teacherName;
  final String? classId;
  final String? className;
  final String? sectionId;
  final String? sectionName;
  final String? subjectId;
  final String? subjectName;
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
    this.className,
    this.sectionId,
    this.sectionName,
    this.subjectId,
    this.subjectName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory OnlineClass.fromJson(Map<String, dynamic> json) {
    String tName = 'Host';
    if (json['host'] != null && json['host'] is Map && json['host']['name'] != null) {
      tName = json['host']['name'].toString();
    } else if (json['teacher'] != null && json['teacher'] is Map && json['teacher']['name'] != null) {
      tName = json['teacher']['name'].toString();
    } else if (json['teacherName'] != null && json['teacherName'].toString().isNotEmpty) {
      tName = json['teacherName'].toString();
    } else if (json['hostName'] != null && json['hostName'].toString().isNotEmpty) {
      tName = json['hostName'].toString();
    }

    String? cName;
    if (json['class'] != null && json['class'] is Map && json['class']['name'] != null) {
      cName = json['class']['name'].toString();
    } else if (json['className'] != null) {
      cName = json['className'].toString();
    }

    String? secName;
    if (json['section'] != null && json['section'] is Map && json['section']['name'] != null) {
      secName = json['section']['name'].toString();
    } else if (json['sectionName'] != null) {
      secName = json['sectionName'].toString();
    }

    String? subName;
    if (json['subject'] != null && json['subject'] is Map && json['subject']['name'] != null) {
      subName = json['subject']['name'].toString();
    } else if (json['subjectName'] != null) {
      subName = json['subjectName'].toString();
    }

    DateTime parsedDate = DateTime.now();
    final rawDate = json['date'] ?? json['scheduledTime'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    return OnlineClass(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      meetLink: json['meetLink']?.toString() ?? '',
      scheduledTime: parsedDate,
      teacherId: json['hostId']?.toString() ?? json['teacherId']?.toString() ?? '',
      teacherName: tName,
      classId: json['classId']?.toString() ?? (json['class'] is Map ? json['class']['id']?.toString() : null),
      className: cName,
      sectionId: json['sectionId']?.toString() ?? (json['section'] is Map ? json['section']['id']?.toString() : null),
      sectionName: secName,
      subjectId: json['subjectId']?.toString() ?? (json['subject'] is Map ? json['subject']['id']?.toString() : null),
      subjectName: subName,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'meetLink': meetLink,
        'scheduledTime': scheduledTime.toIso8601String(),
        'teacherId': teacherId,
        'teacherName': teacherName,
        'classId': classId,
        'className': className,
        'sectionId': sectionId,
        'sectionName': sectionName,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'createdAt': createdAt.toIso8601String(),
      };
}
