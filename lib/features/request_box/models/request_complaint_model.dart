class RequestComplaintUser {
  final String id;
  final String name;
  final String? email;
  final String? role;
  final String? designation;
  final String? avatar;
  final String? phone;
  final List<String> classIds;
  final String? rollNumber;

  const RequestComplaintUser({
    required this.id,
    required this.name,
    this.email,
    this.role,
    this.designation,
    this.avatar,
    this.phone,
    this.classIds = const [],
    this.rollNumber,
  });

  factory RequestComplaintUser.fromJson(Map<String, dynamic> json) {
    List<String> parsedClassIds = [];
    if (json['classIds'] is List) {
      parsedClassIds = (json['classIds'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['classId'] != null) {
      parsedClassIds = [json['classId'].toString()];
    }

    return RequestComplaintUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown User',
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      designation: json['designation']?.toString(),
      avatar: json['avatar']?.toString(),
      phone: json['phone']?.toString(),
      classIds: parsedClassIds,
      rollNumber: json['rollNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'designation': designation,
        'avatar': avatar,
        'phone': phone,
        'classIds': classIds,
        'rollNumber': rollNumber,
      };
}

class RequestComplaintComment {
  final String id;
  final String? requestComplaintId;
  final String? senderId;
  final String message;
  final List<String> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RequestComplaintUser? sender;

  const RequestComplaintComment({
    required this.id,
    this.requestComplaintId,
    this.senderId,
    required this.message,
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
    this.sender,
  });

  factory RequestComplaintComment.fromJson(Map<String, dynamic> json) {
    List<String> parsedAttachments = [];
    if (json['attachments'] is List) {
      parsedAttachments = (json['attachments'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return RequestComplaintComment(
      id: json['id']?.toString() ?? '',
      requestComplaintId: json['requestComplaintId']?.toString(),
      senderId: json['senderId']?.toString(),
      message: json['message']?.toString() ?? '',
      attachments: parsedAttachments,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      sender: json['sender'] is Map<String, dynamic>
          ? RequestComplaintUser.fromJson(json['sender'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestComplaintId': requestComplaintId,
        'senderId': senderId,
        'message': message,
        'attachments': attachments,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        if (sender != null) 'sender': sender!.toJson(),
      };
}

class RequestComplaintModel {
  final String id;
  final String? schoolId;
  final String? senderId;
  final String? recipientId;
  final String? targetRole;
  final String type; // REQUEST, COMPLAINT
  final String category; // ACADEMIC, ATTENDANCE, LEAVE, FACILITY, FEE, DISCIPLINE, BEHAVIOR, EXAM, OTHER
  final String title;
  final String description;
  final String priority; // LOW, MEDIUM, HIGH, URGENT
  final String status; // PENDING, IN_PROGRESS, RESOLVED, REJECTED
  final List<String> attachments;
  final String? resolutionNote;
  final String? resolvedById;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RequestComplaintUser? sender;
  final RequestComplaintUser? recipient;
  final RequestComplaintUser? resolvedBy;
  final List<RequestComplaintComment> comments;

  const RequestComplaintModel({
    required this.id,
    this.schoolId,
    this.senderId,
    this.recipientId,
    this.targetRole,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.attachments = const [],
    this.resolutionNote,
    this.resolvedById,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.sender,
    this.recipient,
    this.resolvedBy,
    this.comments = const [],
  });

  bool get isRequest => type.toUpperCase() == 'REQUEST';
  bool get isComplaint => type.toUpperCase() == 'COMPLAINT';

  RequestComplaintModel copyWith({
    String? status,
    String? resolutionNote,
    String? resolvedById,
    DateTime? resolvedAt,
    List<RequestComplaintComment>? comments,
  }) {
    return RequestComplaintModel(
      id: id,
      schoolId: schoolId,
      senderId: senderId,
      recipientId: recipientId,
      targetRole: targetRole,
      type: type,
      category: category,
      title: title,
      description: description,
      priority: priority,
      status: status ?? this.status,
      attachments: attachments,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      resolvedById: resolvedById ?? this.resolvedById,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sender: sender,
      recipient: recipient,
      resolvedBy: resolvedBy,
      comments: comments ?? this.comments,
    );
  }

  factory RequestComplaintModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedAttachments = [];
    if (json['attachments'] is List) {
      parsedAttachments = (json['attachments'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<RequestComplaintComment> parsedComments = [];
    if (json['comments'] is List) {
      parsedComments = (json['comments'] as List)
          .map((c) {
            try {
              return RequestComplaintComment.fromJson(
                  c as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<RequestComplaintComment>()
          .toList();
    }

    return RequestComplaintModel(
      id: json['id']?.toString() ?? '',
      schoolId: json['schoolId']?.toString(),
      senderId: json['senderId']?.toString(),
      recipientId: json['recipientId']?.toString(),
      targetRole: json['targetRole']?.toString(),
      type: json['type']?.toString().toUpperCase() ?? 'REQUEST',
      category: json['category']?.toString().toUpperCase() ?? 'OTHER',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString().toUpperCase() ?? 'MEDIUM',
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      attachments: parsedAttachments,
      resolutionNote: json['resolutionNote']?.toString(),
      resolvedById: json['resolvedById']?.toString(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      sender: json['sender'] is Map<String, dynamic>
          ? RequestComplaintUser.fromJson(json['sender'])
          : null,
      recipient: json['recipient'] is Map<String, dynamic>
          ? RequestComplaintUser.fromJson(json['recipient'])
          : null,
      resolvedBy: json['resolvedBy'] is Map<String, dynamic>
          ? RequestComplaintUser.fromJson(json['resolvedBy'])
          : null,
      comments: parsedComments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'schoolId': schoolId,
        'senderId': senderId,
        'recipientId': recipientId,
        'targetRole': targetRole,
        'type': type,
        'category': category,
        'title': title,
        'description': description,
        'priority': priority,
        'status': status,
        'attachments': attachments,
        'resolutionNote': resolutionNote,
        'resolvedById': resolvedById,
        'resolvedAt': resolvedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        if (sender != null) 'sender': sender!.toJson(),
        if (recipient != null) 'recipient': recipient!.toJson(),
        if (resolvedBy != null) 'resolvedBy': resolvedBy!.toJson(),
        'comments': comments.map((c) => c.toJson()).toList(),
      };
}
