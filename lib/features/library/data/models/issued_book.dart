import 'book.dart';

class IssuedBook {
  final String id;
  final Book book;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? returnDate;

  const IssuedBook({
    required this.id,
    required this.book,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
  });

  bool get isOverdue {
    if (returnDate != null) return false;
    return DateTime.now().isAfter(dueDate);
  }
}
