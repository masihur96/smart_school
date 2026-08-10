import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../data/dummy_library_data.dart';
import 'id_card_scanner_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  // ── Issue button tap handler ───────────────────────────────────────────────
  Future<void> _onRequestIssue(BuildContext context) async {
    // 1. Open the ID card barcode scanner
    final result = await Navigator.push<ScanResult>(
      context,
      MaterialPageRoute(builder: (_) => const IdCardScannerScreen()),
    );

    // 2. User cancelled the scanner
    if (result == null) return;

    if (!context.mounted) return;

    // 3. Record the issue request with the scanned student info
    DummyLibraryData.addRequest(
      book.id,
      book.title,
      result.studentId,
      result.studentName,
    );

    // 4. Show success confirmation
    _showSuccessDialog(context, result);
  }

  void _showSuccessDialog(BuildContext context, ScanResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success animation
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Issue Requested!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${book.title}" has been requested for:',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _DialogInfoRow(
                      icon: Icons.person_rounded,
                      label: 'Student',
                      value: result.studentName,
                    ),
                    const SizedBox(height: 8),
                    _DialogInfoRow(
                      icon: Icons.badge_rounded,
                      label: 'ID',
                      value: result.studentId,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    Navigator.of(context).pop(); // go back to book list
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3C6E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar with book cover ──────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF1A3C6E),
            foregroundColor: Colors.white,
            centerTitle: true,
            title: Text(
              book.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A3C6E), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Blurred decorative circle
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Book cover
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Hero(
                        tag: 'book_cover_${book.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: book.coverImageUrl,
                              height: 210,
                              width: 150,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: 210,
                                width: 150,
                                color: const Color(0xFF2D4E8A),
                                child: const Icon(Icons.book_rounded,
                                    color: Colors.white54, size: 60),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                height: 210,
                                width: 150,
                                color: const Color(0xFF2D4E8A),
                                child: const Icon(Icons.book_rounded,
                                    color: Colors.white54, size: 60),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Book info ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Author
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 16, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 5),
                      Text(
                        book.author,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status badge row
                  Row(
                    children: [
                      _StatusBadge(isAvailable: book.isAvailable),
                      const SizedBox(width: 10),
                      _CategoryBadge(label: book.category),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Details card
                  _DetailCard(book: book),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.description.isNotEmpty
                        ? book.description
                        : 'No description available for this book.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 100), // bottom padding for button
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Issue button ─────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: book.isAvailable
              ? _IssueButton(onTap: () => _onRequestIssue(context))
              : _UnavailableButton(),
        ),
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _IssueButton extends StatefulWidget {
  final VoidCallback onTap;
  const _IssueButton({required this.onTap});

  @override
  State<_IssueButton> createState() => _IssueButtonState();
}

class _IssueButtonState extends State<_IssueButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3C6E), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Scan ID Card & Request Issue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.block_rounded, color: Color(0xFF9CA3AF), size: 20),
          SizedBox(width: 10),
          Text(
            'Book Currently Unavailable',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Book book;
  const _DetailCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.category_rounded,
            label: 'Category',
            value: book.category,
            color: const Color(0xFF2563EB),
          ),
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.qr_code_rounded,
            label: 'ISBN',
            value: book.isbn,
            color: const Color(0xFF7C3AED),
          ),
          const Divider(height: 20),
          _DetailRow(
            icon: book.isAvailable
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            label: 'Status',
            value: book.isAvailable ? 'Available' : 'Not Available',
            color: book.isAvailable
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isAvailable;
  const _StatusBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFF10B981).withOpacity(0.12)
            : const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'Available' : 'Unavailable',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isAvailable
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DialogInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9CA3AF),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
