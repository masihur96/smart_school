import './models/book.dart';
import './models/issued_book.dart';
import './models/book_request.dart';

class DummyLibraryData {
  static const List<Book> books = [
    Book(
      id: '1',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      isbn: '978-0743273565',
      category: 'Fiction',
      coverImageUrl: 'https://m.media-amazon.com/images/I/71FTb9X6wsL._AC_UF1000,1000_QL80_.jpg',
      isAvailable: true,
      description: 'The story of the mysteriously wealthy Jay Gatsby and his love for the beautiful Daisy Buchanan.',
    ),
    Book(
      id: '2',
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      isbn: '978-0060935467',
      category: 'Classic',
      coverImageUrl: 'https://m.media-amazon.com/images/I/81OthjkJBuL._AC_UF1000,1000_QL80_.jpg',
      isAvailable: false,
      description: 'A novel about the serious issues of rape and racial inequality.',
    ),
    Book(
      id: '3',
      title: '1984',
      author: 'George Orwell',
      isbn: '978-0451524935',
      category: 'Science Fiction',
      coverImageUrl: 'https://m.media-amazon.com/images/I/61ZewDE3beL._AC_UF1000,1000_QL80_.jpg',
      isAvailable: true,
      description: 'Among the seminal texts of the 20th century, Nineteen Eighty-Four is a rare work that grows more haunting as its futuristic purgatory becomes more real.',
    ),
    Book(
      id: '4',
      title: 'Introduction to Algorithms',
      author: 'Thomas H. Cormen',
      isbn: '978-0262033848',
      category: 'Education',
      coverImageUrl: 'https://m.media-amazon.com/images/I/61Pgdn8Ys-L._AC_UF1000,1000_QL80_.jpg',
      isAvailable: true,
      description: 'Some books on algorithms are rigorous but incomplete; others cover masses of material but lack rigor.',
    ),
    Book(
      id: '5',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '978-0132350884',
      category: 'Education',
      coverImageUrl: 'https://m.media-amazon.com/images/I/41xShlnTZTL._AC_UF1000,1000_QL80_.jpg',
      isAvailable: false,
      description: 'Even bad code can function. But if code isn\'t clean, it can bring a development organization to its knees.',
    ),
  ];

  static List<IssuedBook> getIssuedBooks() {
    return [
      IssuedBook(
        id: 'i1',
        book: books.firstWhere((b) => b.id == '2'),
        issueDate: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 4)),
      ),
      IssuedBook(
        id: 'i2',
        book: books.firstWhere((b) => b.id == '5'),
        issueDate: DateTime.now().subtract(const Duration(days: 20)),
        dueDate: DateTime.now().subtract(const Duration(days: 6)), // Overdue
      ),
    ];
  }

  static List<BookRequest> bookRequests = [
    BookRequest(
      id: 'req1',
      bookId: '1',
      bookTitle: 'The Great Gatsby',
      studentId: 's1',
      studentName: 'Alice Smith',
      requestDate: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'pending',
    ),
    BookRequest(
      id: 'req2',
      bookId: '3',
      bookTitle: '1984',
      studentId: 's2',
      studentName: 'Bob Johnson',
      requestDate: DateTime.now().subtract(const Duration(days: 1)),
      status: 'pending',
    ),
  ];

  static void addRequest(String bookId, String bookTitle, String studentId, String studentName) {
    bookRequests.add(
      BookRequest(
        id: 'req${DateTime.now().millisecondsSinceEpoch}',
        bookId: bookId,
        bookTitle: bookTitle,
        studentId: studentId,
        studentName: studentName,
        requestDate: DateTime.now(),
        status: 'pending',
      ),
    );
  }

  static void acceptRequest(String requestId) {
    final index = bookRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      bookRequests[index].status = 'accepted';
    }
  }

  static void declineRequest(String requestId) {
    final index = bookRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      bookRequests[index].status = 'declined';
    }
  }
}
