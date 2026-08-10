import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../admin/providers/setup_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/academic_book.dart';
import '../providers/academic_book_provider.dart';
import '../widgets/academic_book_card.dart';
import 'add_edit_academic_book_screen.dart';
import 'pdf_viewer_screen.dart';

class AcademicBooksDashboardScreen extends StatefulWidget {
  const AcademicBooksDashboardScreen({super.key});

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
  String _selectedSubjectId = 'all';
  bool _isGrid = true;

  @override
  void initState() {
    super.initState();

    _heroAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(
      CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOutCubic),
    );
    _heroAnimCtrl.forward();

    // Fetch books on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthNotifier>();
      context
          .read<AcademicBookNotifier>()
          .fetchBooks(schoolId: auth.user?.schoolId ?? '');
    });
  }

  @override
  void dispose() {
    _heroAnimCtrl.dispose();
    super.dispose();
  }

  // ── Filters ────────────────────────────────────────────────────────────────

  List<AcademicBook> _filteredBooks(List<AcademicBook> all) {
    return all.where((b) {
      final matchesSearch =
          b.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.subjectName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
      final matchesClass =
          _selectedClassId == 'all' || b.classId == _selectedClassId;
      final matchesSubject =
          _selectedSubjectId == 'all' || b.subjectId == _selectedSubjectId;
      return matchesSearch && matchesClass && matchesSubject;
    }).toList();
  }

  // ── Admin check ────────────────────────────────────────────────────────────

  bool _isAdmin(BuildContext context) {
    final role = context.read<AuthNotifier>().user?.role ?? '';
    return role == 'admin' || role == 'super_admin';
  }

  // ── Delete confirmation ────────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, AcademicBook book) async {
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
                child: const Icon(Icons.delete_rounded,
                    color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Book?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              Text(
                '"${book.title}" will be permanently removed.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
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
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Delete',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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
    if (book.pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No PDF available for this book',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PdfViewerScreen(pdfUrl: book.pdfUrl, title: book.title),
      ),
    );
  }

  Future<void> _openAddEdit(BuildContext context,
      {AcademicBook? book}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
                value: context.read<AcademicBookNotifier>()),
            ChangeNotifierProvider.value(
                value: context.read<ClassSetupNotifier>()),
            ChangeNotifierProvider.value(
                value: context.read<SubjectSetupNotifier>()),
            ChangeNotifierProvider.value(value: context.read<AuthNotifier>()),
          ],
          child: AddEditAcademicBookScreen(book: book),
        ),
      ),
    );
    if (result == true && context.mounted) {
      // Refresh
      final auth = context.read<AuthNotifier>();
      context
          .read<AcademicBookNotifier>()
          .fetchBooks(schoolId: auth.user?.schoolId ?? '');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bookNotifier = context.watch<AcademicBookNotifier>();
    final classNotifier = context.watch<ClassSetupNotifier>();
    final subjectNotifier = context.watch<SubjectSetupNotifier>();
    final admin = _isAdmin(context);

    final allBooks = bookNotifier.books;
    final filtered = _filteredBooks(allBooks);

    // Unique subjects from current class filter
    final subjects = _selectedClassId == 'all'
        ? subjectNotifier.subjects.where((s) => !s.isDeleted).toList()
        : subjectNotifier.subjects
            .where((s) =>
                !s.isDeleted && s.classId == _selectedClassId)
            .toList();

    return Scaffold(

      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1A3C6E),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
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
              background: _buildHeroBanner(allBooks.length),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Search ──────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                    hintText: 'Search books or subjects…',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.grey.shade400, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: Colors.grey.shade400, size: 18),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                  ),
                ),
              ),
            ),

            // ── Class filter chips ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All Classes',
                      selected: _selectedClassId == 'all',
                      onTap: () => setState(() {
                        _selectedClassId = 'all';
                        _selectedSubjectId = 'all';
                      }),
                    ),
                    ...classNotifier.classes
                        .where((c) => !c.isDeleted)
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _FilterChip(
                                label: c.name,
                                selected: _selectedClassId == c.id,
                                onTap: () => setState(() {
                                  _selectedClassId = c.id;
                                  _selectedSubjectId = 'all';
                                }),
                              ),
                            )),
                  ],
                ),
              ),
            ),

            // ── Subject filter chips ────────────────────────────────────────
            if (subjects.isNotEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                child: SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(
                        label: 'All Subjects',
                        selected: _selectedSubjectId == 'all',
                        isSubject: true,
                        onTap: () =>
                            setState(() => _selectedSubjectId = 'all'),
                      ),
                      ...subjects.map((s) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _FilterChip(
                              label: s.name,
                              selected: _selectedSubjectId == s.id,
                              isSubject: true,
                              onTap: () => setState(
                                  () => _selectedSubjectId = s.id),
                            ),
                          )),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 8),

            // ── Count header ────────────────────────────────────────────────
            Container(
              color: const Color(0xFFF4F6FB),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} ${filtered.length == 1 ? 'book' : 'books'} found',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Book list / grid ────────────────────────────────────────────
            Expanded(
              child: bookNotifier.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2563EB)),
                        strokeWidth: 2.5,
                      ),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : _isGrid
                          ? _buildGrid(filtered, admin)
                          : _buildList(filtered, admin),
            ),
          ],
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButton: admin
          ? FloatingActionButton.extended(
              onPressed: () => _openAddEdit(context),
              backgroundColor: const Color(0xFF1A3C6E),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Book',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  // ── Hero banner ────────────────────────────────────────────────────────────

  Widget _buildHeroBanner(int totalBooks) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3C6E), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
                  color: Colors.white.withOpacity(0.06)),
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
                  color: Colors.white.withOpacity(0.04)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_book_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Academic Books',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                'Digital soft copies by class & subject',
                                style: TextStyle(
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
                            label: 'Total Books',
                            value: '$totalBooks',
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          _HeroStat(
                            icon: Icons.class_rounded,
                            label: 'Classes',
                            value: context
                                .read<ClassSetupNotifier>()
                                .classes
                                .where((c) => !c.isDeleted)
                                .length
                                .toString(),
                            color: const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 12),
                          _HeroStat(
                            icon: Icons.subject_rounded,
                            label: 'Subjects',
                            value: context
                                .read<SubjectSetupNotifier>()
                                .subjects
                                .where((s) => !s.isDeleted)
                                .length
                                .toString(),
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

  Widget _buildGrid(List<AcademicBook> books, bool admin) {
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
        final book = books[i];
        return AcademicBookCard(
          book: book,
          isAdmin: admin,
          onRead: () => _openPdf(book),
          onEdit: () => _openAddEdit(context, book: book),
          onDelete: () => _confirmDelete(context, book),
        );
      },
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList(List<AcademicBook> books, bool admin) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final book = books[i];
        return AcademicBookListTile(
          book: book,
          isAdmin: admin,
          onRead: () => _openPdf(book),
          onEdit: () => _openAddEdit(context, book: book),
          onDelete: () => _confirmDelete(context, book),
        );
      },
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
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
              child: const Icon(Icons.menu_book_rounded,
                  color: Color(0xFF2563EB), size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Books Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No books match your search.'
                  : 'No academic books have been uploaded yet.',
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
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isSubject;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isSubject = false,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A3C6E);
    final subjectColor = const Color(0xFF7C3AED);
    final activeColor = isSubject ? subjectColor : primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            horizontal: 14, vertical: isSubject ? 4 : 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontSize: isSubject ? 10 : 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
