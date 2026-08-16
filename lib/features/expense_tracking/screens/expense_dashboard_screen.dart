import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../models/financial_story_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_list_tile.dart';
import '../widgets/financial_story_viewer.dart';
import 'add_edit_expense_screen.dart';
import '../../../core/theme/app_colors.dart';

class ExpenseDashboardScreen extends StatefulWidget {
  const ExpenseDashboardScreen({super.key});

  @override
  State<ExpenseDashboardScreen> createState() => _ExpenseDashboardScreenState();
}

class _ExpenseDashboardScreenState extends State<ExpenseDashboardScreen> {
  TransactionFilter _currentFilter = TransactionFilter.all;
  bool _isBalanceVisible = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openStoryViewer(BuildContext context, int index) {
    final provider = context.read<ExpenseProvider>();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => FinancialStoryViewer(
          stories: provider.stories,
          initialStoryIndex: index,
          onStoryViewed: (storyId) {
            provider.markStoryAsViewed(storyId);
          },
        ),
      ),
    );
  }

  void _showAddQuickStoryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final statController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: Color(0xFF6750A4)),
            SizedBox(width: 8),
            Text('Create Fee / Story Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Story Title',
                  hintText: 'e.g. Midterm Fee Collection',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: statController,
                decoration: InputDecoration(
                  labelText: 'Highlight Stat / Amount',
                  hintText: 'e.g. \$14,200 (88% Cleared)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Brief Description',
                  hintText: 'e.g. 150 students cleared fees for upcoming exams...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6750A4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              final newStory = FinancialStory(
                id: 'story_${DateTime.now().millisecondsSinceEpoch}',
                title: titleController.text.trim(),
                subtitle: 'Custom Story',
                icon: Icons.campaign_rounded,
                gradientColors: const [Color(0xFF0284C7), Color(0xFF0369A1)],
                slides: [
                  StorySlide(
                    title: titleController.text.trim(),
                    highlightValue: statController.text.trim().isNotEmpty
                        ? statController.text.trim()
                        : 'Update',
                    subtitle: 'Published by School Treasury',
                    description: descController.text.trim().isNotEmpty
                        ? descController.text.trim()
                        : 'Financial announcement published for administrative records.',
                    badge: 'Treasury Note',
                    badgeColor: const Color(0xFF0284C7),
                    icon: Icons.notifications_active_rounded,
                  ),
                ],
              );
              context.read<ExpenseProvider>().addCustomStory(newStory);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Story note added to top reel!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Post Story'),
          ),
        ],
      ),
    );
  }

  void _showInsightsSummary(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Financial Treasury Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Summary of inflows, disbursements & net margin',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Overview Cards
              _buildInsightMetricRow(
                'All-Time Total Inflow (Fees & Grants)',
                '+\$${provider.totalIncome.toStringAsFixed(2)}',
                const Color(0xFF10B981),
                Icons.arrow_downward_rounded,
              ),
              const SizedBox(height: 10),
              _buildInsightMetricRow(
                'All-Time Total Expenses',
                '-\$${provider.totalExpenses.toStringAsFixed(2)}',
                const Color(0xFFEF4444),
                Icons.arrow_upward_rounded,
              ),
              const SizedBox(height: 10),
              _buildInsightMetricRow(
                'Current Available Balance',
                '\$${provider.walletBalance.toStringAsFixed(2)}',
                const Color(0xFF6366F1),
                Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 10),
              _buildInsightMetricRow(
                'This Month Net Surplus',
                '${provider.thisMonthNet >= 0 ? '+' : ''}\$${provider.thisMonthNet.toStringAsFixed(2)}',
                provider.thisMonthNet >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                Icons.savings_rounded,
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6750A4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Close Overview', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightMetricRow(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'School Wallet & Expenses',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4A148C), // Deep Royal Purple
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Add Story Note',
            icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
            onPressed: () => _showAddQuickStoryDialog(context),
          ),
          Consumer<ExpenseProvider>(
            builder: (context, provider, _) => IconButton(
              tooltip: 'Financial Insights',
              icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
              onPressed: () => _showInsightsSummary(context, provider),
            ),
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final filteredExpenses = provider.getFilteredTransactions(
            filter: _currentFilter,
            query: _searchQuery,
          );

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // 1. Top Fee Stories Reels Section
                SliverToBoxAdapter(
                  child: _buildStoriesReel(context, provider.stories),
                ),

                // 2. Digital Wallet Hero Card
                SliverToBoxAdapter(
                  child: _buildDigitalWalletCard(context, provider),
                ),

                // 3. Quick Summary Metric Row
                SliverToBoxAdapter(
                  child: _buildSummaryMetrics(provider),
                ),

                // 4. Activity Header & Filters
                SliverToBoxAdapter(
                  child: _buildTransactionsHeader(context, provider),
                ),

                // 5. Transactions List
                if (filteredExpenses.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching transactions found.'
                                  : (_currentFilter == TransactionFilter.income
                                      ? 'No fee / income records yet.'
                                      : (_currentFilter == TransactionFilter.expense
                                          ? 'No expense records yet.'
                                          : 'No transaction history found.')),
                              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap "+ Add Money / Fee" or "- Add Expense" to log records.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = filteredExpenses[index];
                        return ExpenseListTile(
                          expense: expense,
                          onDelete: () => provider.deleteExpense(expense.id),
                        );
                      },
                      childCount: filteredExpenses.length,
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingSpeedDial(context),
    );
  }

  // Stories Section
  Widget _buildStoriesReel(BuildContext context, List<FinancialStory> stories) {
    return Container(
      color: const Color(0xFF4A148C).withOpacity(0.04),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, size: 16, color: Color(0xFF6750A4)),
                    SizedBox(width: 6),
                    Text(
                      'Fee & Financial Stories',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tap to view insights',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 94,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: stories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Add Story Button
                  return GestureDetector(
                    onTap: () => _showAddQuickStoryDialog(context),
                    child: Container(
                      width: 72,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6750A4).withOpacity(0.5),
                                width: 1.5,
                                style: BorderStyle.solid,
                              ),
                              color: const Color(0xFF6750A4).withOpacity(0.08),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Color(0xFF6750A4),
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Add Story',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final storyIndex = index - 1;
                final story = stories[storyIndex];

                return GestureDetector(
                  onTap: () => _openStoryViewer(context, storyIndex),
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: story.isViewed
                                ? LinearGradient(
                                    colors: [Colors.grey[400]!, Colors.grey[500]!],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: story.gradientColors,
                                  ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).cardColor,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: story.gradientColors,
                                ),
                              ),
                              child: Icon(
                                story.icon,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          story.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: story.isViewed ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Hero Wallet Card
  Widget _buildDigitalWalletCard(BuildContext context, ExpenseProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E1065), // Rich Purple-Indigo
            Color(0xFF3B0764),
            Color(0xFF1E1B4B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E1065).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative ambient circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.06),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Account Badge & Visibility Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'School Treasury Wallet',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'ACC: SCH-TR-8842',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 10.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _isBalanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.white.withOpacity(0.85),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Balance Label & Amount
                Text(
                  'Available Wallet Balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isBalanceVisible
                      ? '\$${provider.walletBalance.toStringAsFixed(2)}'
                      : '••••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Inflow and Outflow Mini-Chips inside Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      // Total Inflow (Fees & Grants)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: Color(0xFF34D399),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Inflow',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  Text(
                                    _isBalanceVisible
                                        ? '+\$${provider.totalIncome.toStringAsFixed(0)}'
                                        : '••••',
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withOpacity(0.2),
                      ),

                      const SizedBox(width: 10),

                      // Total Outflow (Expenses)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Color(0xFFF87171),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Outflow',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  Text(
                                    _isBalanceVisible
                                        ? '-\$${provider.totalExpenses.toStringAsFixed(0)}'
                                        : '••••',
                                    style: const TextStyle(
                                      color: Color(0xFFF87171),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Action Buttons on Wallet Card
                Row(
                  children: [
                    // + Add Money / Fee
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddEditExpenseScreen(
                                initialType: TransactionType.income,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'Add Money',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // - Add Expense
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddEditExpenseScreen(
                                initialType: TransactionType.expense,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        label: const Text(
                          'Add Expense',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Summary Metrics Row
  Widget _buildSummaryMetrics(ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'Month Inflow',
              amount: provider.thisMonthIncome,
              color: const Color(0xFF10B981),
              icon: Icons.payments_outlined,
              isIncome: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              title: 'Month Expense',
              amount: provider.thisMonthExpenses,
              color: const Color(0xFFEF4444),
              icon: Icons.calendar_month_outlined,
              isIncome: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required bool isIncome,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isIncome ? '+' : '-'}\$${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Transactions Header & Filter Section
  Widget _buildTransactionsHeader(BuildContext context, ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title & count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${provider.expenses.length} Records',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by title, fee category, voucher...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filter Segment Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Transactions',
                  count: provider.expenses.length,
                  isSelected: _currentFilter == TransactionFilter.all,
                  selectedColor: const Color(0xFF6750A4),
                  onTap: () {
                    setState(() {
                      _currentFilter = TransactionFilter.all;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '+ Fees & Income',
                  count: provider.onlyIncomes.length,
                  isSelected: _currentFilter == TransactionFilter.income,
                  selectedColor: const Color(0xFF10B981),
                  onTap: () {
                    setState(() {
                      _currentFilter = TransactionFilter.income;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '- Expenses',
                  count: provider.onlyExpenses.length,
                  isSelected: _currentFilter == TransactionFilter.expense,
                  selectedColor: const Color(0xFFEF4444),
                  onTap: () {
                    setState(() {
                      _currentFilter = TransactionFilter.expense;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSpeedDial(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF4A148C),
      foregroundColor: Colors.white,
      elevation: 4,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Quick Financial Action',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: const Color(0xFF10B981).withOpacity(0.08),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_circle_rounded, color: Color(0xFF10B981)),
                    ),
                    title: const Text(
                      'Add Money / Fee Collection',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Log tuition fees, grants, donations or cash deposits'),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditExpenseScreen(
                            initialType: TransactionType.income,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: AppColors.primaryAdmin.withOpacity(0.08),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAdmin.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove_circle_rounded, color: AppColors.primaryAdmin),
                    ),
                    title: const Text(
                      'Record School Expense',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Log salaries, utility bills, maintenance or supplies'),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditExpenseScreen(
                            initialType: TransactionType.expense,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.add_card_rounded),
      label: const Text(
        'Transaction',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
