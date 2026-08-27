import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/library/screens/add_edit_book_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';

import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/library_book_provider.dart';
import 'book_list_screen.dart';
import 'issued_books_screen.dart';

class LibraryDashboardScreen extends StatefulWidget {
  final String comeFrom;
  const LibraryDashboardScreen({super.key, required this.comeFrom});

  @override
  State<LibraryDashboardScreen> createState() => _LibraryDashboardScreenState();
}

class _LibraryDashboardScreenState extends State<LibraryDashboardScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _heroAnimController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _heroAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _heroAnimController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _heroAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _heroAnimController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = context.watch<LibraryBookNotifier>();
    final user = context.watch<AuthNotifier>().user;
    final isAdmin =
        user?.role == UserRole.admin || user?.role == UserRole.superadmin;

    final totalBooks = notifier.books.length;
    final availableBooks = notifier.books.where((b) => b.isAvailable).length;
    final issuedCount =
        notifier.issuedBooks.where((b) => b.returnDate == null).length;
    final returnedCount =
        notifier.issuedBooks.where((b) => b.returnDate != null).length;
    final overdueCount = notifier.issuedBooks.where((b) => b.isOverdue).length;

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEditBookScreen(isAdminOrTeacher: true),
                  ),
                );
                if (result == true) {}
              },
              backgroundColor: widget.comeFrom == 'admin'
                  ? AppColors.primaryAdmin
                  : widget.comeFrom == 'teacher'
                  ? AppColors.primaryTeacher
                  : AppColors.primaryStudent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                l10n.newBook,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 165,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: widget.comeFrom == 'admin'
                ? AppColors.primaryAdmin
                : widget.comeFrom == 'teacher'
                ? AppColors.primaryTeacher
                : AppColors.primaryStudent,

            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHeroBanner(
                context: context,
                totalBooks: totalBooks,
                availableBooks: availableBooks,
                issuedCount: issuedCount,
                returnedCount: returnedCount,
                overdueCount: overdueCount,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: TabBar(
                  controller: _tabController,

                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(6),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.lightGrey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: l10n.allBooksTab),
                    Tab(text: l10n.issuedTab),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            BookListScreen(comeFrom: widget.comeFrom),
            IssuedBooksScreen(comeFrom: widget.comeFrom),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner({
    required BuildContext context,
    required int totalBooks,
    required int availableBooks,
    required int issuedCount,
    required int returnedCount,
    required int overdueCount,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        // Decorative circles
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
        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20,),
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


                        const SizedBox(width: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.schoolLibrary,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              l10n.manageBooksSubtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatChip(
                            icon: Icons.book_rounded,
                            label: l10n.totalLabel,
                            value: '$totalBooks',
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.check_circle_rounded,
                            label: l10n.availableLabel,
                            value: '$availableBooks',
                            color: const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.bookmark_rounded,
                            label: l10n.issuedLabel,
                            value: '$issuedCount',
                            color: const Color(0xFF60A5FA),
                          ),
                          if (returnedCount > 0) ...[
                            const SizedBox(width: 10),
                            _StatChip(
                              icon: Icons.assignment_turned_in_rounded,
                              label: l10n.returnedLabel,
                              value: '$returnedCount',
                              color: const Color(0xFF34D399),
                            ),
                          ],
                          if (overdueCount > 0) ...[
                            const SizedBox(width: 10),
                            _StatChip(
                              icon: Icons.warning_rounded,
                              label: l10n.overdueLabel,
                              value: '$overdueCount',
                              color: const Color(0xFFFBBF24),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
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
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
