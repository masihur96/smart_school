import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/issued_book.dart';
import '../providers/library_book_provider.dart';
import 'book_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class IssuedBooksScreen extends StatefulWidget {
  final String comeFrom;
  const IssuedBooksScreen({super.key, required this.comeFrom});

  @override
  State<IssuedBooksScreen> createState() => _IssuedBooksScreenState();
}

class _IssuedBooksScreenState extends State<IssuedBooksScreen> {
  String _selectedFilter = 'All';

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

        // ── Filtered data ──────────────────────────────────────────────────
        final overdue = issuedBooks.where((b) => b.isOverdue).toList();
        final active = issuedBooks.where((b) => b.isActive).toList();
        final returned = issuedBooks.where((b) => b.isReturned).toList();

        List<IssuedBook> displayedBooks;
        if (_selectedFilter == 'Issued') {
          displayedBooks = active;
        } else if (_selectedFilter == 'Overdue') {
          displayedBooks = overdue;
        } else if (_selectedFilter == 'Returned') {
          displayedBooks = returned;
        } else {
          displayedBooks = issuedBooks;
        }

        return RefreshIndicator(
          onRefresh: () => notifier.fetchIssuedBooks(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Filter Chips
              _buildFilterChips(
                totalCount: issuedBooks.length,
                activeCount: active.length,
                overdueCount: overdue.length,
                returnedCount: returned.length,
              ),
              const SizedBox(height: 12),

              // Filtered list display
              if (_selectedFilter != 'All') ...[
                if (displayedBooks.isEmpty)
                  _buildNoResultsForFilter(_selectedFilter)
                else
                  ...displayedBooks.map(
                    (ib) => _IssuedBookCard(
                      issuedBook: ib,
                      comeFrom: widget.comeFrom,
                    ),
                  ),
              ] else ...[
                // All: Show sections
                if (overdue.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Overdue',
                    count: overdue.length,
                    color: const Color(0xFFEF4444),
                    icon: Icons.warning_rounded,
                  ),
                  const SizedBox(height: 8),
                  ...overdue.map(
                    (ib) => _IssuedBookCard(
                      issuedBook: ib,
                      comeFrom: widget.comeFrom,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (active.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Currently Issued',
                    count: active.length,
                    color: const Color(0xFF2563EB),
                    icon: Icons.bookmark_rounded,
                  ),
                  const SizedBox(height: 8),
                  ...active.map(
                    (ib) => _IssuedBookCard(
                      issuedBook: ib,
                      comeFrom: widget.comeFrom,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (returned.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Returned History',
                    count: returned.length,
                    color: const Color(0xFF10B981),
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(height: 8),
                  ...returned.map(
                    (ib) => _IssuedBookCard(
                      issuedBook: ib,
                      comeFrom: widget.comeFrom,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  // ─── Filter Chips Row ───────────────────────────────────────────────────────

  Widget _buildFilterChips({
    required int totalCount,
    required int activeCount,
    required int overdueCount,
    required int returnedCount,
  }) {
    final filters = [
      {'label': 'All', 'count': totalCount, 'color': const Color(0xFF1A3C6E)},
      {'label': 'Issued', 'count': activeCount, 'color': const Color(0xFF2563EB)},
      if (overdueCount > 0)
        {'label': 'Overdue', 'count': overdueCount, 'color': const Color(0xFFEF4444)},
      {'label': 'Returned', 'count': returnedCount, 'color': const Color(0xFF10B981)},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final label = filter['label'] as String;
          final count = filter['count'] as int;
          final color = filter['color'] as Color;
          final isSelected = _selectedFilter == label;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = label;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE5E7EB),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.25)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoResultsForFilter(String filter) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'No $filter books found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
          Container(
            width: 58,
            height: 92,
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
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
  final String comeFrom;

  const _IssuedBookCard({required this.issuedBook, required this.comeFrom});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    final isAdmin = comeFrom == 'admin' ||
        user?.role == UserRole.admin ||
        user?.role == UserRole.superadmin;
    final isTeacher = comeFrom == 'teacher' || user?.role == UserRole.teacher;

    final fmt = DateFormat('MMM dd, yyyy');
    final isOverdue = issuedBook.isOverdue;
    final isReturned = issuedBook.isReturned;
    final daysLeft = issuedBook.dueDate.difference(DateTime.now()).inDays;
    final daysOverdue = DateTime.now().difference(issuedBook.dueDate).inDays;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BookDetailScreen(book: issuedBook.book, comeFrom: comeFrom),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOverdue
                ? const Color(0xFFEF4444).withOpacity(0.3)
                : isReturned
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isOverdue
                  ? const Color(0xFFEF4444).withOpacity(0.08)
                  : isReturned
                  ? const Color(0xFF10B981).withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: issuedBook.book.coverImageUrl,
                  cacheKey: issuedBook.book.coverImageUrl.split('?').first,
                  width: 58,
                  height: 96,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 58,
                    height: 96,
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(
                      Icons.book_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 24,
                    ),
                  ),
                  placeholder: (_, __) => Container(
                    width: 58,
                    height: 96,
                    color: const Color(0xFFF3F4F6),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            issuedBook.book.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusBadge(
                          isReturned: isReturned,
                          isOverdue: isOverdue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      issuedBook.book.author,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    // ── Admin: Detailed Student Info Section ─────────────────
                    if (isAdmin) ...[
                      const SizedBox(height: 8),
                      _AdminStudentInfoBox(issuedBook: issuedBook),
                    ] else if (isTeacher &&
                        issuedBook.studentName.isNotEmpty &&
                        issuedBook.studentName != 'Student') ...[
                      // Teacher: Lightweight student indicator with Class / Section
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              issuedBook.studentName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4B5563),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (issuedBook.studentClassName != null &&
                              issuedBook.studentClassName!.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            Text(
                              '(${issuedBook.studentClassName}${issuedBook.studentSectionName != null && issuedBook.studentSectionName!.isNotEmpty ? ' • ${issuedBook.studentSectionName}' : ''})',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // ── Dates Section ────────────────────────────────────────
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _DateRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Issue Date',
                          value: fmt.format(issuedBook.issueDate),
                          color: const Color(0xFF6B7280),
                        ),
                        if (isReturned) ...[
                          _DateRow(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Return Date',
                            value: fmt.format(issuedBook.returnDate!),
                            color: const Color(0xFF059669),
                          ),
                        ] else ...[
                          _DateRow(
                            icon: isOverdue
                               ? Icons.event_busy_rounded
                                : Icons.event_available_rounded,
                            label: 'Due Date',
                            value: fmt.format(issuedBook.dueDate),
                            color: isOverdue
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF2563EB),
                          ),
                          _DateRow(
                            icon: Icons.assignment_return_outlined,
                            label: 'Return Date',
                            value: 'Pending',
                            color: const Color(0xFF9CA3AF),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ── Action / Chip Section ────────────────────────────────
                    Row(
                      children: [
                        if (isReturned)
                          _ReturnedChip(returnDate: issuedBook.returnDate!)
                        else
                          _CountdownChip(
                            isOverdue: isOverdue,
                            daysLeft: isOverdue ? daysOverdue : daysLeft,
                          ),
                        if (isAdmin && !isReturned) ...[
                          const SizedBox(width: 8),
                          _ReturnButton(issuedBook: issuedBook),
                        ],
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

// ─── Admin Student Info Box ──────────────────────────────────────────────────

class _AdminStudentInfoBox extends StatelessWidget {
  final IssuedBook issuedBook;
  const _AdminStudentInfoBox({required this.issuedBook});

  @override
  Widget build(BuildContext context) {
    final avatar = issuedBook.studentAvatar;
    final hasAvatar = avatar != null && avatar.startsWith('http');
    final studentName = issuedBook.studentName.isNotEmpty
        ? issuedBook.studentName
        : 'Unknown Student';
    final initial =
        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S';
    final className = issuedBook.studentClassName;
    final sectionName = issuedBook.studentSectionName;
    final phone = issuedBook.studentPhone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Student Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF1A3C6E).withOpacity(0.12),
            backgroundImage: hasAvatar ? CachedNetworkImageProvider(
                avatar,
                cacheKey: avatar.split('?').first,
              ) : null,
            child: !hasAvatar
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A3C6E),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),

          // Student Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if ((className != null && className.isNotEmpty) ||
                    (sectionName != null && sectionName.isNotEmpty)) ...[
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      if (className != null && className.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A3C6E).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Class: $className',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A3C6E),
                            ),
                          ),
                        ),
                      if (sectionName != null && sectionName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Sec: $sectionName',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isReturned;
  final bool isOverdue;

  const _StatusBadge({required this.isReturned, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (isReturned) {
      bg = const Color(0xFF10B981).withOpacity(0.12);
      fg = const Color(0xFF059669);
      label = 'Returned';
      icon = Icons.check_circle_outline_rounded;
    } else if (isOverdue) {
      bg = const Color(0xFFEF4444).withOpacity(0.12);
      fg = const Color(0xFFDC2626);
      label = 'Overdue';
      icon = Icons.warning_amber_rounded;
    } else {
      bg = const Color(0xFF2563EB).withOpacity(0.12);
      fg = const Color(0xFF2563EB);
      label = 'Issued';
      icon = Icons.bookmark_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
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

class _ReturnedChip extends StatelessWidget {
  final DateTime returnDate;
  const _ReturnedChip({required this.returnDate});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd, yyyy');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_turned_in_rounded,
            size: 13,
            color: Color(0xFF059669),
          ),
          const SizedBox(width: 4),
          Text(
            'Returned on ${fmt.format(returnDate)}',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF059669),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final bool isOverdue;
  final int daysLeft;

  const _CountdownChip({required this.isOverdue, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final color = isOverdue ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final bgColor = color.withOpacity(0.08);
    final text = isOverdue
        ? '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} overdue'
        : daysLeft == 0
        ? 'Due today!'
        : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} remaining';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
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
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
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
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
              size: 13,
              color: Color(0xFF059669),
            ),
            SizedBox(width: 4),
            Text(
              'Mark as Returned',
              style: TextStyle(
                fontSize: 10,
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
