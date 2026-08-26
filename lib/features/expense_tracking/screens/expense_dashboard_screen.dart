import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_list_tile.dart';
import 'add_edit_expense_screen.dart';

enum SummaryPeriod {
  allTime,
  currentMonth,
  currentYear,
}

class ExpenseDashboardScreen extends StatefulWidget {
  const ExpenseDashboardScreen({super.key});

  @override
  State<ExpenseDashboardScreen> createState() => _ExpenseDashboardScreenState();
}

class _ExpenseDashboardScreenState extends State<ExpenseDashboardScreen> {
  TransactionFilter _currentFilter = TransactionFilter.all;
  SummaryPeriod _selectedPeriod = SummaryPeriod.allTime;
  bool _isBalanceVisible = true;
  bool _isFabOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
      context.read<ExpenseProvider>().fetchTransactions(schoolId: schoolId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatMoney(double amount, {bool includeCents = false}) {
    final absAmount = amount.abs();
    final formatter = NumberFormat(
      includeCents || (absAmount % 1 != 0) ? '#,##0.00' : '#,##0',
      'en_US',
    );
    final formatted = formatter.format(absAmount);
    return amount < 0 ? '-৳$formatted' : '৳$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.schoolWalletAndExpensesTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: _buildSpeedDialFab(context),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final filteredExpenses = provider.getFilteredTransactions(
            filter: _currentFilter,
            query: _searchQuery,
          );

          return RefreshIndicator(
            onRefresh: () async {
              final schoolId =
                  context.read<AuthNotifier>().user?.schoolId ?? '';
              await context.read<ExpenseProvider>().fetchTransactions(
                schoolId: schoolId,
              );
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Digital Wallet Hero Card with Period Selector
                SliverToBoxAdapter(
                  child: (provider.isLoading && provider.expenses.isEmpty)
                      ? _buildWalletCardShimmer(context)
                      : _buildDigitalWalletCard(context, provider),
                ),

                // 2. Activity Header & Filters
                SliverToBoxAdapter(
                  child: (provider.isLoading && provider.expenses.isEmpty)
                      ? _buildHeaderShimmer(context)
                      : _buildTransactionsHeader(context, provider),
                ),

                // 3. Transactions List
                if (provider.isLoading && provider.expenses.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildTransactionListShimmer(context),
                  )
                else if (provider.error != null && provider.expenses.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 36,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_off_rounded,
                                size: 40,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                final schoolId =
                                    context
                                        .read<AuthNotifier>()
                                        .user
                                        ?.schoolId ??
                                    '';
                                context
                                    .read<ExpenseProvider>()
                                    .fetchTransactions(schoolId: schoolId);
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(l10n.retryFetching),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryAdmin,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (filteredExpenses.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 36,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 44,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? l10n.noMatchingTransactionsFound
                                  : (_currentFilter == TransactionFilter.income
                                        ? l10n.noIncomeRecordsFound
                                        : (_currentFilter ==
                                                  TransactionFilter.expense
                                              ? l10n.noExpenseRecordsFound
                                              : l10n.noRecentTransactionsRecorded)),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.tapToAddTransactionHint,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final expense = filteredExpenses[index];
                      return ExpenseListTile(expense: expense);
                    }, childCount: filteredExpenses.length),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Hero Wallet Card with Integrated Period Switcher
  Widget _buildDigitalWalletCard(
    BuildContext context,
    ExpenseProvider provider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final allTime = provider.allTimeSummary;
    final currentMonth = provider.currentMonthSummary;
    final currentYear = provider.currentYearSummary;

    // Determine metrics for the currently selected period
    final WalletPeriodSummary selectedSummary;
    final String periodTitle;
    switch (_selectedPeriod) {
      case SummaryPeriod.currentMonth:
        selectedSummary = currentMonth;
        final mName = currentMonth.monthName.isNotEmpty
            ? currentMonth.monthName
            : 'Month ${currentMonth.month ?? DateTime.now().month}';
        final yName = (currentMonth.year ?? DateTime.now().year).toString();
        periodTitle = l10n.netBalanceMonth(mName, yName);
        break;
      case SummaryPeriod.currentYear:
        selectedSummary = currentYear;
        final yName = (currentYear.year ?? DateTime.now().year).toString();
        periodTitle = l10n.netBalanceYear(yName);
        break;
      case SummaryPeriod.allTime:
      default:
        selectedSummary = allTime;
        periodTitle = l10n.availableTreasuryBalanceAllTime;
        break;
    }

    final monthTabLabel = currentMonth.shortMonthName.isNotEmpty
        ? '${currentMonth.shortMonthName} ${currentMonth.year ?? ''}'
        : l10n.thisMonth;
    final yearTabLabel = currentYear.year != null
        ? l10n.fyYear(currentYear.year.toString())
        : l10n.thisYear;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.primaryAdmin,
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
          // Background ambient circles
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
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                // Period Switcher Segment
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodTab(
                        label: l10n.allTimeTab,
                        period: SummaryPeriod.allTime,
                        icon: Icons.all_inclusive_rounded,
                      ),
                      _buildPeriodTab(
                        label: monthTabLabel,
                        period: SummaryPeriod.currentMonth,
                        icon: Icons.calendar_month_rounded,
                      ),
                      _buildPeriodTab(
                        label: yearTabLabel,
                        period: SummaryPeriod.currentYear,
                        icon: Icons.date_range_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Period Label & Net Balance Amount
                Text(
                  periodTitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _isBalanceVisible
                          ? _formatMoney(
                              selectedSummary.netBalance,
                              includeCents: true,
                            )
                          : '••••••••',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isBalanceVisible && selectedSummary.netBalance >= 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          selectedSummary.netBalance > 0
                              ? l10n.surplus
                              : l10n.balanced,
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (_isBalanceVisible)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          l10n.deficit,
                          style: const TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    Spacer(),
                    IconButton(
                      icon: Icon(
                        _isBalanceVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
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

                // Inflow and Outflow Summary Mini-Chips
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      // Total Inflow
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withOpacity(0.25),
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
                                    l10n.totalInflow,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  Text(
                                    _isBalanceVisible
                                        ? '+${_formatMoney(selectedSummary.totalIncome)}'
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

                      // Total Outflow
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withOpacity(0.25),
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
                                    l10n.totalOutflow,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  Text(
                                    _isBalanceVisible
                                        ? '-${_formatMoney(selectedSummary.totalExpense)}'
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


              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab({
    required String label,
    required SummaryPeriod period,
    required IconData icon,
  }) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Transactions Header & Filter Section
  Widget _buildTransactionsHeader(
    BuildContext context,
    ExpenseProvider provider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title & count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentTransactions,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                l10n.recordsCount(provider.expenses.length),
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
              hintText: l10n.searchTransactionsHint,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
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
                  label: l10n.allTransactions,
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
                  label: l10n.feesAndIncomeFilter,
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
                  label: l10n.expensesFilter,
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

  // ── Speed-Dial FAB ─────────────────────────────────────────────────────────
  Widget _buildSpeedDialFab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // "Add Expense" mini FAB
        AnimatedSlide(
          offset: _isFabOpen ? Offset.zero : const Offset(0, 0.5),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _isFabOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.addExpense,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Mini FAB
                  FloatingActionButton.small(
                    heroTag: 'fab_expense',
                    onPressed: _isFabOpen
                        ? () {
                            setState(() => _isFabOpen = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddEditExpenseScreen(
                                  initialType: TransactionType.expense,
                                ),
                              ),
                            );
                          }
                        : null,
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    child: const Icon(Icons.remove_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),

        // "Add Money" mini FAB
        AnimatedSlide(
          offset: _isFabOpen ? Offset.zero : const Offset(0, 0.5),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _isFabOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 160),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.addMoney,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Mini FAB
                  FloatingActionButton.small(
                    heroTag: 'fab_income',
                    onPressed: _isFabOpen
                        ? () {
                            setState(() => _isFabOpen = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddEditExpenseScreen(
                                  initialType: TransactionType.income,
                                ),
                              ),
                            );
                          }
                        : null,
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    child: const Icon(Icons.add_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Main FAB (toggle)
        FloatingActionButton(
          heroTag: 'fab_main',
          onPressed: () => setState(() => _isFabOpen = !_isFabOpen),
          backgroundColor: AppColors.primaryAdmin,
          foregroundColor: Colors.white,
          elevation: 6,
          child: AnimatedRotation(
            turns: _isFabOpen ? 0.125 : 0.0, // 45° rotation when open
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }

  // ── Shimmer Skeleton Helpers ───────────────────────────────────────────────

  /// A helper that wraps [child] in a single Shimmer.fromColors sweep.
  Widget _shimmer({required Widget child, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: child,
    );
  }

  /// Rounded pill placeholder used throughout the shimmer skeletons.
  Widget _shimBox({
    double? w,
    double h = 14,
    double radius = 8,
    Color color = Colors.white,
  }) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  /// Shimmer placeholder that mimics the Digital Wallet Hero Card.
  Widget _buildWalletCardShimmer(BuildContext context) {
    return _shimmer(
      context: context,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        height: 210,
        decoration: BoxDecoration(
          color: AppColors.primaryAdmin.withOpacity(0.55),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period tab row
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Balance label
            _shimBox(w: 180, h: 12),
            const SizedBox(height: 8),
            // Big balance amount
            _shimBox(w: 140, h: 30, radius: 10),
            const SizedBox(height: 18),
            // Inflow / Outflow row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer placeholder that mimics the "Recent Transactions" header,
  /// search bar, and filter chips.
  Widget _buildHeaderShimmer(BuildContext context) {
    return _shimmer(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimBox(w: 160, h: 16),
                _shimBox(w: 64, h: 12),
              ],
            ),
            const SizedBox(height: 12),
            // Search bar placeholder
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 12),
            // Filter chip row
            Row(
              children: [
                _shimBox(w: 110, h: 30, radius: 20),
                const SizedBox(width: 8),
                _shimBox(w: 100, h: 30, radius: 20),
                const SizedBox(width: 8),
                _shimBox(w: 80, h: 30, radius: 20),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  /// Shimmer placeholder that mimics 6 transaction list tiles.
  Widget _buildTransactionListShimmer(BuildContext context) {
    return _shimmer(
      context: context,
      child: Column(
        children: List.generate(6, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Category icon circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + subtitle lines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimBox(w: double.infinity, h: 13),
                      const SizedBox(height: 7),
                      _shimBox(w: 120, h: 11),
                      const SizedBox(height: 6),
                      _shimBox(w: 80, h: 10),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amount column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _shimBox(w: 70, h: 14),
                    const SizedBox(height: 6),
                    _shimBox(w: 50, h: 10),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}


