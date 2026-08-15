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

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      author: json['author']?.toString() ?? 'Unknown Author',
      isbn: json['isbn']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      coverImageUrl: json['coverImageUrl']?.toString() ??
          json['cover_image_url']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
      isAvailable: json['isAvailable'] as bool? ??
          json['available'] as bool? ??
          true,
      description: json['description']?.toString() ?? '',
    );
  }
}
