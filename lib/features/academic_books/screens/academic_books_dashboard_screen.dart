import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/models/user_model.dart';

import '../../../l10n/app_localizations.dart';
import '../../admin/providers/setup_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/academic_book.dart';
import '../providers/academic_book_provider.dart';
import '../widgets/academic_book_card.dart';
import 'add_edit_academic_book_screen.dart';
import 'pdf_viewer_screen.dart';

class AcademicBooksDashboardScreen extends StatefulWidget {
  final String comeFrom;
  const AcademicBooksDashboardScreen({super.key, required this.comeFrom});

  @override
  State<AcademicBooksDashboardScreen> createState() =>
      _AcademicBooksDashboardScreenState();
}

class _AcademicBooksDashboardScreenState
    extends State<AcademicBooksDashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _heroAnimCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  String _searchQuery = '';
  String _selectedClassId = 'all';
  String _selectedSubject = 'all';
  bool _isGrid = true;

  @override
  void initState() {
    super.initState();

    _heroAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOutCubic),
        );
    _heroAnimCtrl.forward();

    // Fetch books and classes on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthNotifier>();
      final schoolId = auth.user?.schoolId ?? '';
      context.read<AcademicBookNotifier>().fetchBooks(schoolId: schoolId);
      if (schoolId.isNotEmpty) {
        context.read<ClassSetupNotifier>().fetchClasses(schoolId);
      }
    });
  }

  @override
  void dispose() {
    _heroAnimCtrl.dispose();
    super.dispose();
  }

  // ── Class name resolver ───────────────────────────────────────────────────

  String _resolveClassName(
    BuildContext context,
    String classId,
    List<dynamic> classes,
    List<AcademicBook> allBooks,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (classId == 'all') return l10n.allClasses;
    for (final c in classes) {
      if (c.id == classId && (c.name as String).isNotEmpty) {
        return c.name;
      }
    }
    for (final b in allBooks) {
      if (b.classId == classId && b.className.isNotEmpty) {
        return b.className;
      }
    }
    return '${l10n.classLabel} ($classId)';
  }

  // ── Role theme color resolver ─────────────────────────────────────────────

  Color _getHeaderColor(UserRole? role) {
    switch (role) {
      case UserRole.teacher:
        return AppColors.primaryTeacher;
      case UserRole.student:
        return AppColors.primaryStudent;
      case UserRole.superadmin:
        return Colors.deepPurple;
      default:
        return AppColors.primaryAdmin;
    }
  }

  // ── Filters ────────────────────────────────────────────────────────────────

  List<AcademicBook> _filteredBooks(List<AcademicBook> all) {
    return all.where((b) {
      final subjectStr = b.subject.isNotEmpty ? b.subject : b.subjectName;
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          subjectStr.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q);
      final matchesClass =
          _selectedClassId == 'all' || b.classId == _selectedClassId;
      final matchesSubject =
          _selectedSubject == 'all' ||
          subjectStr.trim().toLowerCase() ==
              _selectedSubject.trim().toLowerCase();
      return matchesSearch && matchesClass && matchesSubject;
    }).toList();
  }

  // ── Delete confirmation ────────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, AcademicBook book) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = context.read<AcademicBookNotifier>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.deleteBookTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.deleteBookConfirmMessage(book.title),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        l10n.delete,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !context.mounted) return;

    final deleted = await notifier.deleteBook(book.id);
    if (!deleted && context.mounted) {
      notifier.deleteBookLocally(book.id);
    }
  }

  // ── Navigate ───────────────────────────────────────────────────────────────

  void _openPdf(AcademicBook book) {
    final l10n = AppLocalizations.of(context)!;
    if (book.pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.noPdfAvailableForBook,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          pdfUrl: book.pdfUrl,
          title: book.title,
          comeFrom: widget.comeFrom,
        ),
      ),
    );
  }

  Future<void> _openAddEdit(BuildContext context, {AcademicBook? book}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: context.read<AcademicBookNotifier>(),
            ),
            ChangeNotifierProvider.value(
              value: context.read<ClassSetupNotifier>(),
            ),
            ChangeNotifierProvider.value(
              value: context.read<SubjectSetupNotifier>(),
            ),
            ChangeNotifierProvider.value(value: context.read<AuthNotifier>()),
          ],
          child: AddEditAcademicBookScreen(book: book),
        ),
      ),
    );
    if (result == true && context.mounted) {
      // Refresh
      final auth = context.read<AuthNotifier>();
      final schoolId = auth.user?.schoolId ?? '';
      context.read<AcademicBookNotifier>().fetchBooks(schoolId: schoolId, force: true);
      if (schoolId.isNotEmpty) {
        context.read<ClassSetupNotifier>().fetchClasses(schoolId);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authNotifier = context.watch<AuthNotifier>();
    final user = authNotifier.user;
    final isAdmin =
        user != null &&
        (user.role == UserRole.admin || user.role == UserRole.superadmin);

    final bookNotifier = context.watch<AcademicBookNotifier>();
    final classNotifier = context.watch<ClassSetupNotifier>();

    final allBooks = bookNotifier.books;
    final filtered = _filteredBooks(allBooks);
    final headerColor = _getHeaderColor(user?.role);

    // ── Build Class Options from Response & ClassNotifier ────────────────
    final Set<String> seenClassIds = {};
    final List<_DropdownOption> classOptions = [
      _DropdownOption(id: 'all', name: l10n.allClasses),
    ];

    // 1. Classes extracted from the API response
    for (final book in allBooks) {
      if (book.classId.isNotEmpty && !seenClassIds.contains(book.classId)) {
        seenClassIds.add(book.classId);
        classOptions.add(
          _DropdownOption(
            id: book.classId,
            name: _resolveClassName(
              context,
              book.classId,
              classNotifier.classes,
              allBooks,
            ),
          ),
        );
      }
    }

    // 2. Any additional school classes from classNotifier not yet in response
    for (final c in classNotifier.classes.where((c) => !c.isDeleted)) {
      if (!seenClassIds.contains(c.id)) {
        seenClassIds.add(c.id);
        classOptions.add(_DropdownOption(id: c.id, name: c.name));
      }
    }

    // ── Build Subject Options from Response (Filtered by selected class) ──
    final booksForSelectedClass = _selectedClassId == 'all'
        ? allBooks
        : allBooks.where((b) => b.classId == _selectedClassId).toList();

    final Set<String> uniqueSubjects = {};
    for (final b in booksForSelectedClass) {
      final s = b.subject.isNotEmpty ? b.subject.trim() : b.subjectName.trim();
      if (s.isNotEmpty) {
        uniqueSubjects.add(s);
      }
    }

    final List<String> sortedSubjects = uniqueSubjects.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final List<_DropdownOption> subjectOptions = [
      _DropdownOption(id: 'all', name: l10n.allSubjects),
      ...sortedSubjects.map((s) => _DropdownOption(id: s, name: s)),
    ];

    // Ensure currently selected values are safe
    final effectiveClassId = classOptions.any((o) => o.id == _selectedClassId)
        ? _selectedClassId
        : 'all';
    final effectiveSubject = subjectOptions.any((o) => o.id == _selectedSubject)
        ? _selectedSubject
        : 'all';

    // Unique subjects count for hero banner
    final totalSubjectsCount = allBooks
        .map(
          (b) => b.subject.isNotEmpty ? b.subject.trim() : b.subjectName.trim(),
        )
        .where((s) => s.isNotEmpty)
        .toSet()
        .length;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: headerColor,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _isGrid = !_isGrid),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHeroBanner(
                context: context,
                headerColor: headerColor,
                totalBooks: allBooks.length,
                totalClasses: classOptions.length > 1
                    ? classOptions.length - 1
                    : classNotifier.classes.where((c) => !c.isDeleted).length,
                totalSubjects: totalSubjectsCount,
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Search ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l10n.searchBooksOrSubjectsHint,
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

            // ── Class & Subject Dropdowns ────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // ── Class Dropdown ────────────────────────
                  Expanded(
                    child: _FilterDropdown(
                      label: l10n.classLabel,
                      icon: Icons.school_rounded,
                      activeColor: const Color(0xFF1A3C6E),
                      value: effectiveClassId,
                      items: classOptions,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedClassId = val;
                          _selectedSubject = 'all';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ── Subject Dropdown ──────────────────────
                  Expanded(
                    child: _FilterDropdown(
                      label: l10n.subjectLabel,
                      icon: Icons.auto_stories_rounded,
                      activeColor: const Color(0xFF7C3AED),
                      value: effectiveSubject,
                      items: subjectOptions,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedSubject = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Count header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Text(
                    l10n.booksFoundCount(filtered.length),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedClassId != 'all' ||
                      _selectedSubject != 'all' ||
                      _searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedClassId = 'all';
                        _selectedSubject = 'all';
                        _searchQuery = '';
                      }),
                      child: Text(
                        l10n.resetFilters,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Book list / grid ────────────────────────────────────
            Expanded(
              child: bookNotifier.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
                        ),
                        strokeWidth: 2.5,
                      ),
                    )
                  : filtered.isEmpty
                  ? _buildEmptyState(context)
                  : _isGrid
                  ? _buildGrid(
                      filtered,
                      isAdmin,
                      allBooks,
                      classNotifier.classes,
                    )
                  : _buildList(
                      filtered,
                      isAdmin,
                      allBooks,
                      classNotifier.classes,
                    ),
            ),
          ],
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openAddEdit(context),
              backgroundColor: const Color(0xFF1A3C6E),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                l10n.addBookButton,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  // ── Hero banner ────────────────────────────────────────────────────────────

  Widget _buildHeroBanner({
    required BuildContext context,
    required Color headerColor,
    required int totalBooks,
    required int totalClasses,
    required int totalSubjects,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(color: headerColor),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(50, 8, 20, 16),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.academicBooksTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                l10n.academicBooksSubtitle,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _HeroStat(
                            icon: Icons.picture_as_pdf_rounded,
                            label: l10n.totalBooksStat,
                            value: '$totalBooks',
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          _HeroStat(
                            icon: Icons.class_rounded,
                            label: l10n.classesStat,
                            value: '$totalClasses',
                            color: const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 12),
                          _HeroStat(
                            icon: Icons.subject_rounded,
                            label: l10n.subjectsStat,
                            value: '$totalSubjects',
                            color: const Color(0xFF60A5FA),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid ───────────────────────────────────────────────────────────────────

  Widget _buildGrid(
    List<AcademicBook> books,
    bool admin,
    List<AcademicBook> allBooks,
    List<dynamic> classes,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, i) {
        final rawBook = books[i];
        final displayBook = rawBook.className.isEmpty
            ? rawBook.copyWith(
                className: _resolveClassName(
                  context,
                  rawBook.classId,
                  classes,
                  allBooks,
                ),
              )
            : rawBook;
        return AcademicBookCard(
          book: displayBook,
          isAdmin: admin,
          onRead: () => _openPdf(displayBook),
          onEdit: () => _openAddEdit(context, book: rawBook),
          onDelete: () => _confirmDelete(context, rawBook),
        );
      },
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList(
    List<AcademicBook> books,
    bool admin,
    List<AcademicBook> allBooks,
    List<dynamic> classes,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final rawBook = books[i];
        final displayBook = rawBook.className.isEmpty
            ? rawBook.copyWith(
                className: _resolveClassName(
                  context,
                  rawBook.classId,
                  classes,
                  allBooks,
                ),
              )
            : rawBook;
        return AcademicBookListTile(
          book: displayBook,
          isAdmin: admin,
          onRead: () => _openPdf(displayBook),
          onEdit: () => _openAddEdit(context, book: rawBook),
          onDelete: () => _confirmDelete(context, rawBook),
        );
      },
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF2563EB),
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noBooksFoundTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? l10n.noBooksMatchSearch
                  : l10n.noAcademicBooksUploadedYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero stat chip ─────────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dropdown Option Model ──────────────────────────────────────────────────────

class _DropdownOption {
  final String id;
  final String name;

  const _DropdownOption({required this.id, required this.name});
}

// ── Filter Dropdown Widget ─────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color activeColor;
  final String value;
  final List<_DropdownOption> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isFiltered = value != 'all';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.any((i) => i.id == value) ? value : items.first.id,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isFiltered ? activeColor : const Color(0xFF6B7280),
              size: 18,
            ),
            borderRadius: BorderRadius.circular(14),
            // dropdownColor: Colors.white,
            elevation: 4,
            style: const TextStyle(fontSize: 13),
            items: items.map((opt) {
              final isItemActive = opt.id == value;
              return DropdownMenuItem<String>(
                value: opt.id,
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: isItemActive
                          ? activeColor
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opt.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isItemActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isItemActive
                              ? activeColor
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
