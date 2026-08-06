import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/dummy_library_data.dart';
import 'book_detail_screen.dart';

class IssuedBooksScreen extends StatelessWidget {
  const IssuedBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final issuedBooks = DummyLibraryData.getIssuedBooks();
    final dateFormat = DateFormat('MMM dd, yyyy');

    if (issuedBooks.isEmpty) {
      return const Center(child: Text('No books currently issued.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: issuedBooks.length,
      itemBuilder: (context, index) {
        final issuedBook = issuedBooks[index];
        final isOverdue = issuedBook.isOverdue;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailScreen(book: issuedBook.book),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          issuedBook.book.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Overdue',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Issued: ${dateFormat.format(issuedBook.issueDate)}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event_busy, size: 16, color: isOverdue ? Colors.red : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Due: ${dateFormat.format(issuedBook.dueDate)}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey[700],
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
