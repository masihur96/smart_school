class OnlineClassParticipant {
  final String uuid;
  final String name;
  final String? avatar;

  OnlineClassParticipant({
    required this.uuid,
    required this.name,
    this.avatar,
  });

  factory OnlineClassParticipant.fromJson(Map<String, dynamic> json) {
    return OnlineClassParticipant(
      uuid: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        'avatar': avatar,
      };
}

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
  final List<OnlineClassParticipant> participants;

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
    this.participants = const [],
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
    final classObj = json['class'] ?? json['Class'];
    if (classObj != null && classObj is Map && classObj['Name'] != null) {
      cName = classObj['Name'].toString();
    } else if (classObj != null && classObj is Map && classObj['name'] != null) {
      cName = classObj['name'].toString();
    } else if (json['className'] != null) {
      cName = json['className'].toString();
    }

    String? secName;
    final sectionObj = json['section'] ?? json['Sections'] ?? json['Section'];
    if (sectionObj != null && sectionObj is Map && sectionObj['Name'] != null) {
      secName = sectionObj['Name'].toString();
    } else if (sectionObj != null && sectionObj is Map && sectionObj['name'] != null) {
      secName = sectionObj['name'].toString();
    } else if (json['sectionName'] != null) {
      secName = json['sectionName'].toString();
    }

    String? subName;
    final subjectObj = json['subject'] ?? json['Subject'];
    if (subjectObj != null && subjectObj is Map && subjectObj['Name'] != null) {
      subName = subjectObj['Name'].toString();
    } else if (subjectObj != null && subjectObj is Map && subjectObj['name'] != null) {
      subName = subjectObj['name'].toString();
    } else if (json['subjectName'] != null) {
      subName = json['subjectName'].toString();
    }

    DateTime parsedDate = DateTime.now();
    final rawDate = json['date'] ?? json['scheduledTime'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }
    
    List<OnlineClassParticipant> parsedParticipants = [];
    final partsList = json['participants'] ?? json['participantList'] ?? json['participant'] ?? json['Participants'];
    if (partsList != null && partsList is List) {
      parsedParticipants = (partsList as List)
          .map((e) => OnlineClassParticipant.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return OnlineClass(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      meetLink: json['meetLink']?.toString() ?? '',
      scheduledTime: parsedDate,
      teacherId: json['hostId']?.toString() ?? json['teacherId']?.toString() ?? '',
      teacherName: tName,
      classId: json['classId']?.toString() ?? (classObj is Map ? (classObj['uuid']?.toString() ?? classObj['id']?.toString()) : null),
      className: cName,
      sectionId: json['sectionId']?.toString() ?? (sectionObj is Map ? (sectionObj['uuid']?.toString() ?? sectionObj['id']?.toString()) : null),
      sectionName: secName,
      subjectId: json['subjectId']?.toString() ?? (subjectObj is Map ? (subjectObj['uuid']?.toString() ?? subjectObj['id']?.toString()) : null),
      subjectName: subName,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      participants: parsedParticipants,
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
        'participants': participants.map((p) => p.toJson()).toList(),
      };
}
