class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final String coverImageUrl;
  final bool isAvailable;
  final String description;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    required this.coverImageUrl,
    this.isAvailable = true,
    this.description = '',
  });
}
