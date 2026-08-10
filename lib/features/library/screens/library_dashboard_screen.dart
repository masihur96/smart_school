import 'package:flutter/material.dart';
import '../data/dummy_library_data.dart';
import 'book_list_screen.dart';
import 'issued_books_screen.dart';

class LibraryDashboardScreen extends StatefulWidget {
  const LibraryDashboardScreen({super.key});

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
    _fadeAnim = CurvedAnimation(parent: _heroAnimController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroAnimController, curve: Curves.easeOutCubic));
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
    final totalBooks = DummyLibraryData.books.length;
    final availableBooks = DummyLibraryData.books.where((b) => b.isAvailable).length;
    final issuedBooks = DummyLibraryData.getIssuedBooks().length;
    final overdueBooks = DummyLibraryData.getIssuedBooks().where((b) => b.isOverdue).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1A3C6E),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHeroBanner(
                totalBooks: totalBooks,
                availableBooks: availableBooks,
                issuedCount: issuedBooks,
                overdueCount: overdueBooks,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF1A3C6E),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(6),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: '📚  All Books'),
                    Tab(text: '🔖  Issued'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            BookListScreen(),
            IssuedBooksScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner({
    required int totalBooks,
    required int availableBooks,
    required int issuedCount,
    required int overdueCount,
  }) {
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
                            child: const Icon(Icons.local_library_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'School Library',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          'Manage books & track issues',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.book_rounded,
                            label: 'Total',
                            value: '$totalBooks',
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.check_circle_rounded,
                            label: 'Available',
                            value: '$availableBooks',
                            color: const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.bookmark_rounded,
                            label: 'Issued',
                            value: '$issuedCount',
                            color: const Color(0xFF60A5FA),
                          ),
                          if (overdueCount > 0) ...[
                            const SizedBox(width: 10),
                            _StatChip(
                              icon: Icons.warning_rounded,
                              label: 'Overdue',
                              value: '$overdueCount',
                              color: const Color(0xFFFBBF24),
                            ),
                          ],
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
