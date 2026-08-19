import 'book.dart';

class IssuedBookStudent {
  final String id;
  final String name;
  final String? phone;
  final String? avatar;
  final String? className;
  final String? sectionName;
  final String? role;

  const IssuedBookStudent({
    required this.id,
    required this.name,
    this.phone,
    this.avatar,
    this.className,
    this.sectionName,
    this.role,
  });

  factory IssuedBookStudent.fromJson(Map<String, dynamic> json) {
    return IssuedBookStudent(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      className: json['className']?.toString(),
      sectionName: json['sectionName']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class IssuedBook {
  final String id;
  final String? schoolId;
  final String? bookId;
  final Book book;
  final String studentId;
  final String studentName;
  final IssuedBookStudent? student;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const IssuedBook({
    required this.id,
    this.schoolId,
    this.bookId,
    required this.book,
    required this.studentId,
    required this.studentName,
    this.student,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    this.createdAt,
    this.updatedAt,
  });

  bool get isReturned => returnDate != null;

  bool get isOverdue {
    if (returnDate != null) return false;
    return DateTime.now().isAfter(dueDate);
  }

  bool get isActive => returnDate == null && !isOverdue;

  String? get studentClassName => student?.className;
  String? get studentSectionName => student?.sectionName;
  String? get studentPhone => student?.phone;
  String? get studentAvatar => student?.avatar;

  factory IssuedBook.fromJson(Map<String, dynamic> json) {
    final bookJson = json['book'] as Map<String, dynamic>? ?? {};

    IssuedBookStudent? student;
    if (json['student'] is Map<String, dynamic>) {
      try {
        student = IssuedBookStudent.fromJson(
          json['student'] as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    final studentJson = json['student'] as Map<String, dynamic>? ?? {};
    final studentName = student?.name.isNotEmpty == true
        ? student!.name
        : (studentJson['name']?.toString() ??
            json['studentName']?.toString() ??
            'Student');
    final studentId = student?.id.isNotEmpty == true
        ? student!.id
        : (json['studentId']?.toString() ??
            studentJson['id']?.toString() ??
            '');

    return IssuedBook(
      id: json['id']?.toString() ?? '',
      schoolId: json['schoolId']?.toString(),
      bookId: json['bookId']?.toString(),
      book: Book.fromJson(bookJson),
      studentId: studentId,
      studentName: studentName,
      student: student,
      issueDate: _parseDate(json['issueDate'] ?? json['createdAt']) ??
          DateTime.now(),
      dueDate: _parseDate(json['dueDate']) ?? DateTime.now(),
      returnDate: _parseDate(json['returnDate']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }
}
