import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/issued_book.dart';
import '../providers/library_book_provider.dart';
import 'book_detail_screen.dart';

class IssuedBooksScreen extends StatefulWidget {
  const IssuedBooksScreen({super.key});

  @override
  State<IssuedBooksScreen> createState() => _IssuedBooksScreenState();
}

class _IssuedBooksScreenState extends State<IssuedBooksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryBookNotifier>().fetchIssuedBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryBookNotifier>(
      builder: (context, notifier, _) {
        // ── Loading ────────────────────────────────────────────────────────
        if (notifier.isIssuedLoading) {
          return _buildShimmer();
        }

        // ── Error ──────────────────────────────────────────────────────────
        if (notifier.issuedError != null && notifier.issuedBooks.isEmpty) {
          return _buildError(notifier);
        }

        // ── Empty ──────────────────────────────────────────────────────────
        final issuedBooks = notifier.issuedBooks;
        if (issuedBooks.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => notifier.fetchIssuedBooks(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: _buildEmptyState(),
                ),
              ],
            ),
          );
        }

        // ── Data ───────────────────────────────────────────────────────────
        final overdue = issuedBooks.where((b) => b.isOverdue).toList();
        final onTime = issuedBooks.where((b) => !b.isOverdue).toList();

        return RefreshIndicator(
          onRefresh: () => notifier.fetchIssuedBooks(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (overdue.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Overdue',
                  count: overdue.length,
                  color: const Color(0xFFEF4444),
                  icon: Icons.warning_rounded,
                ),
                const SizedBox(height: 8),
                ...overdue.map((ib) => _IssuedBookCard(issuedBook: ib)),
                const SizedBox(height: 16),
              ],
              if (onTime.isNotEmpty) ...[
                _SectionHeader(
                  label: 'On Track',
                  count: onTime.length,
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 8),
                ...onTime.map((ib) => _IssuedBookCard(issuedBook: ib)),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Shimmer skeleton ──────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF8F8F8),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => _skeletonCard(),
      ),
    );
  }

  static Widget _box(double w, double h, {double r = 8}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFDEDEDE),
          borderRadius: BorderRadius.circular(r),
        ),
      );

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover placeholder
          Container(
            width: 58,
            height: 82,
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
                Row(
                  children: [
                    Expanded(child: _box(double.infinity, 14, r: 30)),
                    const SizedBox(width: 8),
                    _box(52, 22, r: 6),
                  ],
                ),
                const SizedBox(height: 6),
                _box(100, 11, r: 30),
                const SizedBox(height: 12),
                _box(130, 11, r: 30),
                const SizedBox(height: 6),
                _box(120, 11, r: 30),
                const SizedBox(height: 8),
                _box(90, 22, r: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError(LibraryBookNotifier notifier) {
    return RefreshIndicator(
      onRefresh: () => notifier.fetchIssuedBooks(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notifier.issuedError ?? 'Something went wrong',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => notifier.fetchIssuedBooks(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A3C6E).withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 40,
              color: Color(0xFF1A3C6E),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Books Issued',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'All books are currently available.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull down to refresh',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Issued book card ─────────────────────────────────────────────────────────

class _IssuedBookCard extends StatelessWidget {
  final IssuedBook issuedBook;

  const _IssuedBookCard({required this.issuedBook});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.superadmin;

    final fmt = DateFormat('MMM dd, yyyy');
    final isOverdue = issuedBook.isOverdue;
    final daysLeft = issuedBook.dueDate.difference(DateTime.now()).inDays;
    final daysOverdue = DateTime.now().difference(issuedBook.dueDate).inDays;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(book: issuedBook.book),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOverdue
                ? const Color(0xFFEF4444).withOpacity(0.25)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isOverdue
                  ? const Color(0xFFEF4444).withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  issuedBook.book.coverImageUrl,
                  width: 58,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 58,
                    height: 82,
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(
                      Icons.book_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 24,
                    ),
                  ),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          width: 58,
                          height: 82,
                          color: const Color(0xFFF3F4F6),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            issuedBook.book.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(isOverdue: isOverdue),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issuedBook.book.author,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    // Student name (from API)
                    if (issuedBook.studentName.isNotEmpty &&
                        issuedBook.studentName != 'Student') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            issuedBook.studentName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Date rows
                    _DateRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Issued',
                      value: fmt.format(issuedBook.issueDate),
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 5),
                    _DateRow(
                      icon: isOverdue
                          ? Icons.event_busy_rounded
                          : Icons.event_available_rounded,
                      label: 'Due',
                      value: fmt.format(issuedBook.dueDate),
                      color: isOverdue
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 8),
                    // Countdown chip
                    _CountdownChip(
                      isOverdue: isOverdue,
                      daysLeft: isOverdue ? daysOverdue : daysLeft,
                    ),
                    // Return button (only for admin and if not already returned)
                    if (isAdmin && issuedBook.returnDate == null) ...[  
                      const SizedBox(height: 10),
                      _ReturnButton(issuedBook: issuedBook),
                    ],
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

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isOverdue;
  const _StatusBadge({required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue
            ? const Color(0xFFEF4444).withOpacity(0.1)
            : const Color(0xFF2563EB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOverdue ? 'Overdue' : 'Issued',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isOverdue
              ? const Color(0xFFDC2626)
              : const Color(0xFF2563EB),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final bool isOverdue;
  final int daysLeft;

  const _CountdownChip({required this.isOverdue, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final color =
        isOverdue ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final bgColor = color.withOpacity(0.08);
    final text = isOverdue
        ? '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} overdue'
        : daysLeft == 0
            ? 'Due today!'
            : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} remaining';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue
                ? Icons.access_time_filled_rounded
                : Icons.hourglass_top_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnButton extends StatelessWidget {
  final IssuedBook issuedBook;

  const _ReturnButton({required this.issuedBook});

  Future<void> _handleReturn(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Return Book',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to mark "${issuedBook.book.title}" as returned by ${issuedBook.studentName}?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Return Book'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      await context.read<LibraryBookNotifier>().returnBook(issuedBook.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(); // close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Book marked as returned successfully!',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleReturn(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_return_rounded,
              size: 14,
              color: Color(0xFF059669),
            ),
            SizedBox(width: 6),
            Text(
              'Mark as Returned',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF059669),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

