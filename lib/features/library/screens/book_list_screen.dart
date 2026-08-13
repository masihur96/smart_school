import 'package:flutter/material.dart';

import '../data/dummy_library_data.dart';
import '../models/book.dart';
import '../widgets/book_grid_card.dart';
import 'book_detail_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _gridView = true;

  List<String> get _categories {
    final cats = DummyLibraryData.books.map((b) => b.category).toSet().toList()
      ..sort();
    return ['All', ...cats];
  }

  List<Book> get _filteredBooks {
    return DummyLibraryData.books.where((book) {
      final matchesSearch =
          book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat =
          _selectedCategory == 'All' || book.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final books = _filteredBooks;

    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildCategoryChips(),
          _buildResultsHeader(books.length),
          Expanded(
            child: books.isEmpty
                ? _buildEmptyState()
                : _gridView
                ? _buildGridView(books)
                : _buildListView(books),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search title or author…',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ViewToggleButton(
            isGrid: _gridView,
            onToggle: () => setState(() => _gridView = !_gridView),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final cat = _categories[i];
            final selected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1A3C6E)
                      : const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF1A3C6E)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Container(
      color: const Color(0xFFF4F6FB),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'book' : 'books'} found',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3C6E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 14,
                  color: const Color(0xFF1A3C6E),
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedCategory,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1A3C6E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Book> books) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookGridCard(
          book: book,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Book> books) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final book = books[index];
        return _BookListTile(
          book: book,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No books found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search or category',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final bool isGrid;
  final VoidCallback onToggle;

  const _ViewToggleButton({required this.isGrid, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1A3C6E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A3C6E).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _BookListTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookListTile({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  book.coverImageUrl,
                  width: 62,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 62,
                    height: 88,
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(
                      Icons.book_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 28,
                    ),
                  ),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          width: 62,
                          height: 88,
                          color: const Color(0xFFF3F4F6),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _CategoryBadge(label: book.category),
                        const Spacer(),
                        _AvailabilityBadge(isAvailable: book.isAvailable),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFF10B981).withOpacity(0.12)
            : const Color(0xFFEF4444).withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isAvailable ? 'Available' : 'Issued',
            style: TextStyle(
              fontSize: 10,
              color: isAvailable
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
