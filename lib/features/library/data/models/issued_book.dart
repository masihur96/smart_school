import 'book.dart';

class IssuedBook {
  final String id;
  final Book book;
  final String studentId;
  final String studentName;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? returnDate;

  const IssuedBook({
    required this.id,
    required this.book,
    required this.studentId,
    required this.studentName,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
  });

  bool get isOverdue {
    if (returnDate != null) return false;
    return DateTime.now().isAfter(dueDate);
  }

  factory IssuedBook.fromJson(Map<String, dynamic> json) {
    final bookJson = json['book'] as Map<String, dynamic>? ?? {};

    // Student info may come as nested object or flat fields
    final studentJson = json['student'] as Map<String, dynamic>? ?? {};
    final studentUser = studentJson['user'] as Map<String, dynamic>? ?? {};
    final studentName = studentUser['name']?.toString() ??
        json['studentName']?.toString() ??
        'Student';
    final studentId =
        json['studentId']?.toString() ?? studentJson['id']?.toString() ?? '';

    return IssuedBook(
      id: json['id']?.toString() ?? '',
      book: Book.fromJson(bookJson),
      studentId: studentId,
      studentName: studentName,
      issueDate: _parseDate(json['issueDate'] ?? json['createdAt']) ??
          DateTime.now(),
      dueDate: _parseDate(json['dueDate']) ?? DateTime.now(),
      returnDate: _parseDate(json['returnDate']),
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
