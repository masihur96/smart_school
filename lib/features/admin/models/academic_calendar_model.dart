import 'package:flutter/material.dart';

class AcademicCalendarClass {
  final String id;
  final String name;

  AcademicCalendarClass({required this.id, required this.name});

  factory AcademicCalendarClass.fromJson(Map<String, dynamic> json) {
    return AcademicCalendarClass(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class AcademicCalendarCreator {
  final String id;
  final String name;
  final String? avatar;
  final String? role;

  AcademicCalendarCreator({
    required this.id,
    required this.name,
    this.avatar,
    this.role,
  });

  factory AcademicCalendarCreator.fromJson(Map<String, dynamic> json) {
    return AcademicCalendarCreator(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (avatar != null) 'avatar': avatar,
    if (role != null) 'role': role,
  };
}

class AcademicCalendarEvent {
  final String id;
  final String schoolId;
  final String title;
  final String? description;
  final String category; // VACATION, EXAM, EVENT, HOLIDAY, MEETING, etc.
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime;
  final String? endTime;
  final bool isAllDay;
  final bool isHoliday;
  final String targetAudience; // ALL, STUDENT, TEACHER, STAFF, etc.
  final List<String> classIds;
  final List<AcademicCalendarClass> classes;
  final String? color;
  final String? location;
  final String? attachmentUrl;
  final String? academicYear;
  final String? term;
  final String? createdById;
  final AcademicCalendarCreator? createdBy;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AcademicCalendarEvent({
    required this.id,
    required this.schoolId,
    required this.title,
    this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.isHoliday = false,
    this.targetAudience = 'ALL',
    this.classIds = const [],
    this.classes = const [],
    this.color,
    this.location,
    this.attachmentUrl,
    this.academicYear,
    this.term,
    this.createdById,
    this.createdBy,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AcademicCalendarEvent.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    final rawClasses = json['classes'];
    List<AcademicCalendarClass> parsedClasses = [];
    if (rawClasses is List) {
      parsedClasses = rawClasses
          .whereType<Map<String, dynamic>>()
          .map((c) => AcademicCalendarClass.fromJson(c))
          .toList();
    }

    final rawClassIds = json['classIds'];
    List<String> parsedClassIds = [];
    if (rawClassIds is List) {
      parsedClassIds = rawClassIds.map((c) => c.toString()).toList();
    }

    return AcademicCalendarEvent(
      id: json['id']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? 'EVENT',
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      isAllDay: json['isAllDay'] == true,
      isHoliday: json['isHoliday'] == true,
      targetAudience: json['targetAudience']?.toString() ?? 'ALL',
      classIds: parsedClassIds,
      classes: parsedClasses,
      color: json['color']?.toString(),
      location: json['location']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      academicYear: json['academicYear']?.toString(),
      term: json['term']?.toString(),
      createdById: json['createdById']?.toString(),
      createdBy: json['createdBy'] is Map<String, dynamic>
          ? AcademicCalendarCreator.fromJson(
              json['createdBy'] as Map<String, dynamic>,
            )
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    String formatDate(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    return {
      'title': title,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'category': category.toUpperCase(),
      'startDate': formatDate(startDate),
      'endDate': formatDate(endDate),
      if (startTime != null && startTime!.isNotEmpty) 'startTime': startTime,
      if (endTime != null && endTime!.isNotEmpty) 'endTime': endTime,
      'isAllDay': isAllDay,
      'isHoliday': isHoliday,
      'targetAudience': targetAudience,
      'classIds': classIds,
      if (color != null && color!.isNotEmpty) 'color': color,
      if (location != null && location!.isNotEmpty) 'location': location,
      if (attachmentUrl != null && attachmentUrl!.isNotEmpty)
        'attachmentUrl': attachmentUrl,
      if (academicYear != null && academicYear!.isNotEmpty)
        'academicYear': academicYear,
      if (term != null && term!.isNotEmpty) 'term': term,
    };
  }

  Color get displayColor {
    if (color != null && color!.isNotEmpty) {
      try {
        String hex = color!.replaceAll('#', '').trim();
        if (hex.length == 6) hex = 'FF$hex';
        if (hex.length == 8) return Color(int.parse('0x$hex'));
      } catch (_) {}
    }

    switch (category.toUpperCase()) {
      case 'VACATION':
        return const Color(0xFFE53935); // Crimson Red
      case 'HOLIDAY':
        return const Color(0xFFF97316); // Amber / Orange
      case 'EXAM':
        return const Color(0xFF8B5CF6); // Purple
      case 'EVENT':
        return const Color(0xFF0D9488); // Teal
      case 'MEETING':
        return const Color(0xFF2563EB); // Royal Blue
      case 'SPORTS':
        return const Color(0xFF10B981); // Emerald
      default:
        return const Color(0xFF1E3A8A); // Deep Indigo
    }
  }

  bool occursOn(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }

  String get startDateFormatted {
    final y = startDate.year.toString().padLeft(4, '0');
    final m = startDate.month.toString().padLeft(2, '0');
    final d = startDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get endDateFormatted {
    final y = endDate.year.toString().padLeft(4, '0');
    final m = endDate.month.toString().padLeft(2, '0');
    final d = endDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
