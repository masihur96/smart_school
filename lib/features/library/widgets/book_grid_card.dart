import 'package:flutter/material.dart';
import '../models/book.dart';

class BookGridCard extends StatefulWidget {
  final Book book;
  final VoidCallback onTap;

  const BookGridCard({super.key, required this.book, required this.onTap});

  @override
  State<BookGridCard> createState() => _BookGridCardState();
}

class _BookGridCardState extends State<BookGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleCtrl.reverse();
  void _onTapUp(TapUpDetails _) => _scaleCtrl.forward();
  void _onTapCancel() => _scaleCtrl.forward();

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image section
                Expanded(
                  flex: 6,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Book cover
                      Image.network(
                        book.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _CoverPlaceholder(
                            category: book.category),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return _CoverLoadingSkeleton();
                        },
                      ),
                      // Gradient overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color(0xCC000000),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Availability badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _PillBadge(isAvailable: book.isAvailable),
                      ),
                      // Category bottom-left
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            book.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Info section
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Author
                        Row(
                          children: [
                            const Icon(Icons.person_rounded,
                                size: 11, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                book.author,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Tap hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'View details',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF2563EB).withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 9,
                                color:
                                    const Color(0xFF2563EB).withOpacity(0.7)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final bool isAvailable;
  const _PillBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAvailable
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444))
                .withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        isAvailable ? 'Available' : 'Issued',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final String category;
  const _CoverPlaceholder({required this.category});

  Color get _bgColor {
    switch (category) {
      case 'Fiction':
        return const Color(0xFF4F46E5);
      case 'Classic':
        return const Color(0xFF7C3AED);
      case 'Science Fiction':
        return const Color(0xFF0891B2);
      case 'Education':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF1A3C6E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_rounded, color: Colors.white.withOpacity(0.7), size: 40),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              category,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverLoadingSkeleton extends StatefulWidget {
  @override
  State<_CoverLoadingSkeleton> createState() => _CoverLoadingSkeletonState();
}

class _CoverLoadingSkeletonState extends State<_CoverLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(color: const Color(0xFFE5E7EB)),
    );
  }
}
