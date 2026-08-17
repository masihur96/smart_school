import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../data/models/book.dart';
import '../providers/library_book_provider.dart';
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

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryBookNotifier>().fetchBooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _categories(List<Book> books) {
    final cats = books.map((b) => b.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<Book> _filteredBooks(List<Book> books) {
    return books.where((book) {
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
    return Consumer<LibraryBookNotifier>(
      builder: (context, notifier, _) {
        if (notifier.isLoading) {
          return Scaffold(
            body: Column(
              children: [
                _buildSearchAndFilter(notifier),
                _buildCategoryChipsShimmer(),
                _buildResultsHeaderShimmer(),
                Expanded(
                  child: _gridView
                      ? _buildGridShimmer()
                      : _buildListShimmer(),
                ),
              ],
            ),
          );
        }

        final allBooks = notifier.books;
        final books = _filteredBooks(allBooks);
        final cats = _categories(allBooks);

        return Scaffold(
          body: Column(
            children: [
              _buildSearchAndFilter(notifier),
              _buildCategoryChips(cats),
              _buildResultsHeader(books.length),
              if (notifier.error != null && allBooks.isEmpty)
                _buildErrorBanner(notifier)
              else
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
      },
    );
  }

  // ─── Shimmer Helpers ──────────────────────────────────────────────────────

  static Widget _shimBox(double w, double h, {double r = 8}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFDEDEDE),
          borderRadius: BorderRadius.circular(r),
        ),
      );

  /// Skeleton for the category chip row
  Widget _buildCategoryChipsShimmer() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8E8E8),
        highlightColor: const Color(0xFFF8F8F8),
        child: SizedBox(
          height: 34,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, __) => _shimBox(72, 34, r: 20),
          ),
        ),
      ),
    );
  }

  /// Skeleton for the results header row
  Widget _buildResultsHeaderShimmer() {
    return Container(
      color: const Color(0xFFF4F6FB),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8E8E8),
        highlightColor: const Color(0xFFF8F8F8),
        child: Row(
          children: [
            _shimBox(100, 13, r: 30),
            const Spacer(),
            _shimBox(60, 26, r: 8),
          ],
        ),
      ),
    );
  }

  /// Skeleton that mirrors the 2-column BookGridCard layout
  Widget _buildGridShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF8F8F8),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => _buildGridCardSkeleton(),
      ),
    );
  }

  Widget _buildGridCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 155,
              color: const Color(0xFFDEDEDE),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimBox(double.infinity, 12, r: 30),
                const SizedBox(height: 6),
                _shimBox(80, 10, r: 30),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _shimBox(50, 20, r: 6),
                    const Spacer(),
                    _shimBox(54, 20, r: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton that mirrors the _BookListTile layout
  Widget _buildListShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF8F8F8),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => _buildListTileSkeleton(),
      ),
    );
  }

  Widget _buildListTileSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover thumbnail placeholder
            Container(
              width: 62,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimBox(double.infinity, 14, r: 30),
                  const SizedBox(height: 6),
                  _shimBox(120, 11, r: 30),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _shimBox(55, 20, r: 6),
                      const Spacer(),
                      _shimBox(60, 20, r: 6),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(LibraryBookNotifier notifier) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              notifier.error ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => notifier.fetchBooks(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(LibraryBookNotifier notifier) {
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
                controller: _searchController,
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
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
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

  Widget _buildCategoryChips(List<String> categories) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final cat = categories[i];
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
                const Icon(
                  Icons.filter_list_rounded,
                  size: 14,
                  color: Color(0xFF1A3C6E),
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
                child: book.coverImageUrl.isNotEmpty
                    ? Image.network(
                        book.coverImageUrl,
                        width: 62,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderCover(),
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    width: 62,
                                    height: 88,
                                    color: const Color(0xFFF3F4F6),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                      )
                    : _placeholderCover(),
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

  Widget _placeholderCover() {
    return Container(
      width: 62,
      height: 88,
      color: const Color(0xFFE5E7EB),
      child: const Icon(
        Icons.book_rounded,
        color: Color(0xFF9CA3AF),
        size: 28,
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
