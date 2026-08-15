class BookRequest {
  final String id;
  final String bookId;
  final String bookTitle;
  final String studentId;
  final String studentName;
  final DateTime requestDate;
  String status; // 'pending', 'accepted', 'declined'

  BookRequest({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.studentId,
    required this.studentName,
    required this.requestDate,
    this.status = 'pending',
  });
}
