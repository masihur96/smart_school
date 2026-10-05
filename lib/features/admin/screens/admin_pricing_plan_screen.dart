import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/custom_size.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/admin/providers/teacher_provider.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/super_admin/models/pricing_plan_model.dart';
import 'package:smart_school/features/super_admin/models/subscription_model.dart';
import 'package:smart_school/features/super_admin/providers/pricing_notifier.dart';
import 'package:smart_school/features/super_admin/providers/subscription_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/presntation/views/login_screen.dart';

class AdminPricingPlanScreen extends StatefulWidget {
  const AdminPricingPlanScreen({super.key});

  @override
  State<AdminPricingPlanScreen> createState() => _AdminPricingPlanScreenState();
}

class _AdminPricingPlanScreenState extends State<AdminPricingPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool? _filterIsActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchData() {
    final auth = context.read<AuthNotifier>();
    final schoolId = auth.user?.schoolId ?? auth.adminSubscription?.schoolId;
    context.read<PricingNotifier>().fetchPricingPlans();
    context.read<SubscriptionNotifier>().fetchSubscriptionHistory(
      schoolId: schoolId,
      isActive: _filterIsActive,
      page: 1,
      limit: 20,
      sortBy: 'createdAt',
      sortOrder: 'DESC',
    );
  }

  Future<void> _refreshHistory() async {
    final auth = context.read<AuthNotifier>();
    final schoolId = auth.user?.schoolId ?? auth.adminSubscription?.schoolId;
    await context.read<SubscriptionNotifier>().fetchSubscriptionHistory(
      schoolId: schoolId,
      isActive: _filterIsActive,
      page: 1,
      limit: 20,
      sortBy: 'createdAt',
      sortOrder: 'DESC',
    );
  }

  void _onFilterChanged(bool? isActive) {
    if (_filterIsActive == isActive) return;
    setState(() {
      _filterIsActive = isActive;
    });
    final auth = context.read<AuthNotifier>();
    final schoolId = auth.user?.schoolId ?? auth.adminSubscription?.schoolId;
    context.read<SubscriptionNotifier>().fetchSubscriptionHistory(
      schoolId: schoolId,
      isActive: _filterIsActive,
      page: 1,
      limit: 20,
      sortBy: 'createdAt',
      sortOrder: 'DESC',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authNotifier = context.watch<AuthNotifier>();
    final pricingNotifier = context.watch<PricingNotifier>();
    final subscriptionNotifier = context.watch<SubscriptionNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.systemSubscription,
          style: TextStyle(
            fontSize: screenSize(context, .04),
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryAdmin,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
              await context.read<AuthNotifier>().logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.layers_outlined),
              text: 'Available Plans',
            ),
            Tab(
              icon: Icon(Icons.history_rounded),
              text: 'Plan History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlansTab(
            pricingNotifier,
            authNotifier,
            subscriptionNotifier,
            l10n,
          ),
          _buildHistoryTab(
            subscriptionNotifier,
            authNotifier,
            l10n,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansTab(
    PricingNotifier pricingNotifier,
    AuthNotifier authNotifier,
    SubscriptionNotifier subscriptionNotifier,
    AppLocalizations l10n,
  ) {
    final subscription = subscriptionNotifier.activeSubscription ??
        authNotifier.adminSubscription;

    return RefreshIndicator(
      onRefresh: () async {
        _fetchData();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildStatusBanner(
            authNotifier,
            l10n,
            activeSub: subscriptionNotifier.activeSubscription,
          ),
          if (pricingNotifier.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (pricingNotifier.plans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.noPricingPlansAvailable),
                    TextButton(
                      onPressed: () => pricingNotifier.fetchPricingPlans(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: pricingNotifier.plans.map((plan) {
                  final isPlanFree = plan.pricePerMonth == '0' ||
                      plan.name.toLowerCase().contains('free');
                  final isSubscriptionExpired = subscription != null &&
                      !authNotifier.isSubscriptionValid;

                  // Hide free plan cards when any current plan is expired
                  if (isPlanFree && isSubscriptionExpired) {
                    return const SizedBox.shrink();
                  }

                  final teacherNotifier = context.read<TeachersNotifier>();
                  final studentNotifier = context.read<StudentsNotifier>();
                  int totalUser =
                      teacherNotifier.totalCount + studentNotifier.totalCount;

                  return _AdminPricingPlanCard(
                    plan: plan,
                    currentCount: totalUser,
                    isActive: subscription?.pricingPlan?.id == plan.id,
                    isAlreadyUsedFreePlan: isPlanFree,
                    onPlanUpdated: _fetchData,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(
    SubscriptionNotifier subscriptionNotifier,
    AuthNotifier authNotifier,
    AppLocalizations l10n,
  ) {
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildFilterChips(),
          if (subscriptionNotifier.historySummary != null)
            _buildHistorySummary(
              subscriptionNotifier.historySummary!,
              subscriptionNotifier.activeSubscription,
            ),
          if (subscriptionNotifier.isHistoryLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (subscriptionNotifier.historyError != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subscriptionNotifier.historyError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshHistory,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAdmin,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (subscriptionNotifier.historySubscriptions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No subscription history found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _filterIsActive == true
                          ? 'No active subscriptions found for this school.'
                          : 'No subscription records found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _refreshHistory,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Records (${subscriptionNotifier.historySubscriptions.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  ...subscriptionNotifier.historySubscriptions.map(
                    (sub) => _buildHistoryCard(sub),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Active Plans',
            isSelected: _filterIsActive == true,
            onSelected: () => _onFilterChanged(true),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'All History',
            isSelected: _filterIsActive == null,
            onSelected: () => _onFilterChanged(null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Inactive / Expired',
            isSelected: _filterIsActive == false,
            onSelected: () => _onFilterChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryAdmin.withOpacity(0.2),
      checkmarkColor: AppColors.primaryAdmin,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryAdmin : Colors.grey.shade700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryAdmin : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildHistorySummary(
    SubscriptionSummary summary,
    Subscription? activeSub,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryAdmin.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryAdmin.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryMetric(
              icon: Icons.receipt_long_outlined,
              label: 'Total Plans',
              value: '${summary.totalSubscriptions}',
              color: AppColors.primaryAdmin,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: _buildSummaryMetric(
              icon: Icons.payments_outlined,
              label: 'Total Paid',
              value: '৳${summary.totalAmountPaid}',
              color: Colors.green.shade700,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: _buildSummaryMetric(
              icon: summary.hasActiveSubscription
                  ? Icons.verified
                  : Icons.warning_amber_rounded,
              label: 'Status',
              value: summary.hasActiveSubscription ? 'Active' : 'Inactive',
              color: summary.hasActiveSubscription ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Subscription item) {
    final planName = item.pricingPlan?.name ?? 'Standard Plan';
    final planDesc = item.pricingPlan?.description ?? '';
    final isItemActive =
        (item.isActive || item.status == 'active') && item.isExpired != true;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isItemActive
              ? Colors.green.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
          width: isItemActive ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAdmin.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.primaryAdmin,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          planName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(item),
              ],
            ),
            if (planDesc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                planDesc,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${formatDate(item.startDate)} - ${formatDate(item.endDate)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (item.daysRemaining != null &&
                    (item.isActive || item.status == 'active'))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.daysRemaining} days left',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 15,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.lastStudentCount} students',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                if (item.amount != null ||
                    item.pricingPlan?.pricePerMonth != null)
                  Text(
                    '৳${item.amount ?? item.pricingPlan?.pricePerMonth}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryAdmin,
                    ),
                  ),
              ],
            ),
            if (item.paymentMethod != null ||
                (item.transactionId != null &&
                    item.transactionId!.isNotEmpty)) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    if (item.paymentMethod != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAdmin.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.paymentMethod!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryAdmin,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (item.transactionId != null &&
                        item.transactionId!.isNotEmpty) ...[
                      Expanded(
                        child: Text(
                          'Trx: ${item.transactionId}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: item.transactionId!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction ID copied!'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.copy,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${formatDate(item.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                if (item.school?.name != null &&
                    item.school!.name.isNotEmpty)
                  Flexible(
                    child: Text(
                      item.school!.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
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

  Widget _buildStatusChip(Subscription item) {
    final status = item.status?.toLowerCase();
    final isExpired = item.isExpired == true;
    final isActive = (item.isActive || status == 'active') && !isExpired;

    Color color;
    String label;
    IconData icon;

    if (isActive) {
      color = Colors.green;
      label = 'Active';
      icon = Icons.check_circle_outline;
    } else if (status == 'pending') {
      color = Colors.orange;
      label = 'Pending';
      icon = Icons.hourglass_top_outlined;
    } else {
      color = Colors.red;
      label = 'Expired';
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(String? utcDate) {
    if (utcDate == null || utcDate.isEmpty) {
      return '--';
    }

    try {
      final localDate = DateTime.parse(utcDate).toLocal();
      return DateFormat('dd MMM yyyy').format(localDate);
    } catch (_) {
      return utcDate.split('T')[0];
    }
  }

  Widget _buildStatusBanner(
    AuthNotifier auth,
    AppLocalizations l10n, {
    Subscription? activeSub,
  }) {
    final sub = activeSub ?? auth.adminSubscription;
    final isValid = activeSub != null
        ? ((activeSub.isActive || activeSub.status == 'active') &&
            activeSub.isExpired != true)
        : auth.isSubscriptionValid;

    String title = l10n.noActiveSubscription;
    String message = l10n.noActiveSubscriptionDesc;
    Color color = Colors.red;
    IconData icon = Icons.warning_amber_rounded;

    if (isValid && sub != null) {
      title = l10n.activeSubscription;
      final remainingInfo = sub.daysRemaining != null
          ? ' (${sub.daysRemaining} days remaining)'
          : '';
      message =
          '${l10n.activeSubscriptionDesc(sub.pricingPlan?.name ?? 'Standard', formatDate(sub.endDate))}$remainingInfo';
      color = AppColors.primaryAdmin;
      icon = Icons.check_circle_rounded;
    } else if (sub != null && !isValid) {
      title = l10n.subscriptionExpired;
      message = l10n.subscriptionExpiredDesc(sub.endDate.split('T')[0]);
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminPricingPlanCard extends StatefulWidget {
  final PricingPlan plan;
  final int currentCount;
  final bool isActive;
  final bool isAlreadyUsedFreePlan;
  final VoidCallback? onPlanUpdated;

  const _AdminPricingPlanCard({
    required this.plan,
    required this.currentCount,
    required this.isActive,
    this.isAlreadyUsedFreePlan = false,
    this.onPlanUpdated,
  });

  @override
  State<_AdminPricingPlanCard> createState() => _AdminPricingPlanCardState();
}

class _AdminPricingPlanCardState extends State<_AdminPricingPlanCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),

      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.plan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.plan.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.customPlan,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.isActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primaryAdmin,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          l10n.yourCurrentPlan,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(widget.plan.description, style: TextStyle(fontSize: 14)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFeature(
                      Icons.people_outline,
                      l10n.studentsCount(
                        widget.currentCount,
                        widget.plan.maxStudents,
                      ),
                    ),
                    _buildFeature(
                      Icons.calendar_today_outlined,
                      l10n.monthlyBilling,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),

                Row(
                  children: [
                    Text(
                      '৳${widget.plan.pricePerMonth}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(l10n.perMonth),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _isLoading || widget.isAlreadyUsedFreePlan
                ? null
                : () async {
                    final auth = context.read<AuthNotifier>();
                    final isFree =
                        widget.plan.pricePerMonth == '0' ||
                        widget.plan.name.toLowerCase().contains('free');

                    if (isFree) {
                      setState(() {
                        _isLoading = true;
                      });

                      final success = await auth.assignPricingPlan(
                        widget.plan.id!,
                        true,
                      );

                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }

                      if (success && context.mounted) {
                        widget.onPlanUpdated?.call();
                        if (auth.isSubscriptionValid) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminDashboardScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      } else if (context.mounted) {
                        final l10n = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              auth.error ?? l10n.failedToAssignPlan,
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } else {
                      _showPaymentBottomSheet(context, widget.plan, auth);
                    }
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: widget.isAlreadyUsedFreePlan
                    ? Colors.grey
                    : AppColors.primaryAdmin,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.isAlreadyUsedFreePlan
                            ? l10n.alreadyUsedFreePlan
                            : l10n.choosePlan,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: widget.isAlreadyUsedFreePlan ? 12 : 14,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentBottomSheet(
    BuildContext context,
    PricingPlan plan,
    AuthNotifier auth,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _PaymentBottomSheetContent(
          plan: plan,
          auth: auth,
          onSuccess: (method, trxId) {
            Navigator.pop(context);
            widget.onPlanUpdated?.call();
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.paymentSubmittedSuccessfully),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSuccessDialog(
    BuildContext context,
    AuthNotifier auth,
    PricingPlan plan, {
    String? paymentMethod,
    String? trxId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      dialogL10n.perfectChoice,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dialogL10n.planRegisteredDesc(plan.name),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _sendRequestEmail(
                          auth,
                          plan,
                          paymentMethod: paymentMethod,
                          trxId: trxId,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(dialogL10n.activationRequestSent),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(dialogL10n.sendActivationRequest),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(dialogL10n.decideLater),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendRequestEmail(
    AuthNotifier auth,
    PricingPlan plan, {
    String? paymentMethod,
    String? trxId,
  }) async {
    final user = auth.user;
    final String subject = Uri.encodeComponent(
      'Plan Activation Request: ${plan.name}',
    );

    String bodyText =
        'Hello Admin,\n\n'
        'I have selected the ${plan.name} plan for my school.\n'
        'Please accept my registration and activate the plan.\n\n';

    if (paymentMethod != null && trxId != null) {
      bodyText +=
          'Payment Details:\n'
          'Method: $paymentMethod\n'
          'Transaction ID: $trxId\n\n';
    }

    bodyText +=
        'User Details:\n'
        'Name: ${user?.name}\n'
        'Email: ${user?.email}\n'
        'School ID: ${user?.schoolId}\n\n'
        'Regards,\n'
        '${user?.name}';

    final String body = Uri.encodeComponent(bodyText);

    final Uri emailUri = Uri.parse(
      'mailto:masihur.work@gmail.com?subject=$subject&body=$body',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      log('Could not launch $emailUri');
    }
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _PaymentBottomSheetContent extends StatefulWidget {
  final PricingPlan plan;
  final AuthNotifier auth;
  final Function(String paymentMethod, String trxId) onSuccess;

  const _PaymentBottomSheetContent({
    required this.plan,
    required this.auth,
    required this.onSuccess,
  });

  @override
  State<_PaymentBottomSheetContent> createState() =>
      _PaymentBottomSheetContentState();
}

class _PaymentBottomSheetContentState
    extends State<_PaymentBottomSheetContent> {
  String _selectedMethod = 'bKash';
  final _trxIdController = TextEditingController();
  bool _isLoading = false;
  String? _trxError;
  String? _submitError;

  final Map<String, String> _paymentNumbers = {
    'bKash': '01740719204',
    'Nagad': '01740719204',
    'Rocket': '01740719204',
    'Bank': '01740719204',
  };

  @override
  void dispose() {
    _trxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.paymentDetails,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryAdmin.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryAdmin.withOpacity(0.3),
                ),
              ),
              child: Text(
                l10n.paymentInstructions('৳${widget.plan.pricePerMonth}'),
                style: TextStyle(fontSize: 14, color: AppColors.primaryAdmin),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.selectPaymentMethod,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _paymentNumbers.keys.map((method) {
                final isSelected = _selectedMethod == method;
                return ChoiceChip(
                  label: Text(method),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedMethod = method);
                    }
                  },
                  selectedColor: AppColors.primaryAdmin.withOpacity(0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.sendMoneyTo(_selectedMethod),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey(_selectedMethod),
              initialValue: _paymentNumbers[_selectedMethod],
              readOnly: true,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: const Icon(
                  Icons.copy,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.amount,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: '৳${widget.plan.pricePerMonth}',
              readOnly: true,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.transactionId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _trxIdController,
              decoration: InputDecoration(
                hintText: l10n.enterTransactionId,
                errorText: _trxError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (val) {
                if (_trxError != null && val.trim().isNotEmpty) {
                  setState(() => _trxError = null);
                }
              },
            ),
            const SizedBox(height: 24),
            if (_submitError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _submitError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_trxIdController.text.trim().isEmpty) {
                          setState(
                            () => _trxError = l10n.pleaseEnterTransactionId,
                          );
                          return;
                        }
                        setState(() {
                          _trxError = null;
                          _submitError = null;
                          _isLoading = true;
                        });

                        final success = await widget.auth.assignPricingPlan(
                          widget.plan.id!,
                          false,
                          paymentMethod: _selectedMethod,
                          transactionId: _trxIdController.text.trim(),
                          amount: num.tryParse(widget.plan.pricePerMonth),
                        );

                        if (mounted) {
                          setState(() => _isLoading = false);
                        }

                        if (success && mounted) {
                          widget.onSuccess(
                            _selectedMethod,
                            _trxIdController.text.trim(),
                          );
                        } else if (mounted) {
                          setState(() {
                            _submitError =
                                widget.auth.error ?? l10n.failedToAssignPlan;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAdmin,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.submitPayment,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
