import 'package:flutter/material.dart';
import 'package:smart_school/l10n/app_localizations.dart';

import '../data/models/book.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image section
                Expanded(
                  flex: 65,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Book cover
                      Image.network(
                        book.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _CoverPlaceholder(category: book.category),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return _CoverLoadingSkeleton();
                        },
                      ),
                      // Gradient overlay for better badge visibility
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 50,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black87, Colors.transparent],
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
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            book.category.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Info section
                Expanded(
                  flex: 35,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          book.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Author
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                book.author,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (isAvailable
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444))
                    .withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        isAvailable ? l10n.availableLabel : l10n.issuedLabel,
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
          Icon(
            Icons.book_rounded,
            color: Colors.white.withOpacity(0.7),
            size: 40,
          ),
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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
