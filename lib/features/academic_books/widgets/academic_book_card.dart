import 'package:flutter/material.dart';
import '../models/academic_book.dart';

class AcademicBookCard extends StatelessWidget {
  final AcademicBook book;
  final VoidCallback onRead;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const AcademicBookCard({
    super.key,
    required this.book,
    required this.onRead,
    this.onEdit,
    this.onDelete,
    this.isAdmin = false,
  });

  // Derive a consistent color from the subject name
  Color _subjectColor() {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFF0891B2),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFFDB2777),
      const Color(0xFF65A30D),
    ];
    final idx = book.subjectName.isEmpty
        ? 0
        : book.subjectName.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top banner ─────────────────────────────────────────────────────
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.85), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                // Decorative circle
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                // PDF icon + subject badge
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const Spacer(),
                          if (isAdmin)
                            _AdminMenu(
                              onEdit: onEdit,
                              onDelete: onDelete,
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Class badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.className.isNotEmpty
                              ? book.className
                              : 'Unknown Class',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      book.subjectName.isNotEmpty
                          ? book.subjectName
                          : 'General',
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Expanded(
                    child: Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Read button
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: onRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.85), color],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'Read PDF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Admin kebab menu ───────────────────────────────────────────────────────────

class _AdminMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _AdminMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 4,
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit_rounded, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Edit',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_rounded, size: 16, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Delete',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444))),
            ],
          ),
        ),
      ],
    );
  }
}

// ── List tile variant ──────────────────────────────────────────────────────────

class AcademicBookListTile extends StatelessWidget {
  final AcademicBook book;
  final VoidCallback onRead;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const AcademicBookListTile({
    super.key,
    required this.book,
    required this.onRead,
    this.onEdit,
    this.onDelete,
    this.isAdmin = false,
  });

  Color _subjectColor() {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFF0891B2),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFFDB2777),
      const Color(0xFF65A30D),
    ];
    final idx = book.subjectName.isEmpty
        ? 0
        : book.subjectName.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor();
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _SmallChip(label: book.className, color: const Color(0xFF1A3C6E)),
                    const SizedBox(width: 6),
                    _SmallChip(label: book.subjectName, color: color),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isAdmin)
                _AdminMenu(onEdit: onEdit, onDelete: onDelete),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onRead,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Read',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label.isNotEmpty ? label : '—',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
