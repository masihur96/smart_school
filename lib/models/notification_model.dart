import 'dart:convert';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? recipientId;
  final bool isRead;
  final String? schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    this.recipientId,
    required this.isRead,
    this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      recipientId: json['recipientId'],
      isRead: json['isRead'] ?? false,
      schoolId: json['schoolId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'recipientId': recipientId,
      'isRead': isRead,
      'schoolId': schoolId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<NotificationModel> fromList(List<dynamic> list) {
    return list.map((item) => NotificationModel.fromJson(item)).toList();
  }
}
