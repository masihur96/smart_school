import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/l10n/app_localizations.dart';

import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';

enum SubscriptionFilter { all, active, inactive, expired }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionFilter _selectedFilter = SubscriptionFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionNotifier>().fetchSubscriptions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isExpired(Subscription subscription) {
    if (subscription.endDate.isEmpty) return false;
    try {
      final end = DateTime.parse(subscription.endDate);
      return DateTime.now().isAfter(end);
    } catch (_) {
      return false;
    }
  }

  List<Subscription> _getFilteredSubscriptions(List<Subscription> allSubs) {
    // 1. Filter by status
    List<Subscription> statusFiltered;
    switch (_selectedFilter) {
      case SubscriptionFilter.all:
        statusFiltered = allSubs;
        break;
      case SubscriptionFilter.active:
        statusFiltered = allSubs
            .where((s) => s.isActive && !_isExpired(s))
            .toList();
        break;
      case SubscriptionFilter.inactive:
        statusFiltered = allSubs
            .where((s) => !s.isActive && !_isExpired(s))
            .toList();
        break;
      case SubscriptionFilter.expired:
        statusFiltered = allSubs.where((s) => _isExpired(s)).toList();
        break;
    }

    // 2. Filter by search query
    if (_searchQuery.isEmpty) {
      return statusFiltered;
    }

    return statusFiltered.where((sub) {
      final schoolName = sub.school?.name.toLowerCase() ?? '';
      final email = sub.school?.email.toLowerCase() ?? '';
      final phone = sub.school?.phone.toLowerCase() ?? '';
      final schoolId = sub.schoolId.toLowerCase();

      return schoolName.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          schoolId.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<SubscriptionNotifier>().fetchSubscriptions(),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(theme),

            _buildSubscriptionList(theme),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryDark,
      title: const Text(
        'Subscriptions',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 22,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -10,
              child: Icon(
                Icons.analytics_rounded,
                size: 160,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(theme),
              const SizedBox(height: 16),
              _buildFilterTabs(theme),
            ],
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search by school name, email, or ID...',
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip('All', SubscriptionFilter.all, theme),
          const SizedBox(width: 8),
          _buildFilterChip('Active', SubscriptionFilter.active, theme),
          const SizedBox(width: 8),
          _buildFilterChip('Inactive', SubscriptionFilter.inactive, theme),
          const SizedBox(width: 8),
          _buildFilterChip('Expired', SubscriptionFilter.expired, theme),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    SubscriptionFilter filter,
    ThemeData theme,
  ) {
    final isSelected = _selectedFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && _selectedFilter != filter) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDark : Colors.grey,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: Colors.white,
      backgroundColor: Colors.white.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.white : Colors.transparent),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildSubscriptionList(ThemeData theme) {
    return Consumer<SubscriptionNotifier>(
      builder: (context, notifier, child) {
        if (notifier.isLoading && notifier.subscriptions.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (notifier.error != null && notifier.subscriptions.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      notifier.error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => notifier.fetchSubscriptions(),
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.retry),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
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
          );
        }

        final filteredSubscriptions = _getFilteredSubscriptions(
          notifier.subscriptions,
        );

        if (filteredSubscriptions.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: AppColors.textMuted.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No subscriptions found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try changing the filter or your search term.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final subscription = filteredSubscriptions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 10),
                child: SubscriptionCard(subscription: subscription),
              );
            }, childCount: filteredSubscriptions.length),
          ),
        );
      },
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionCard({super.key, required this.subscription});

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isActive = subscription.isActive;
    final plan = subscription.pricingPlan;
    final school = subscription.school;

    final bool isExpired = () {
      if (subscription.endDate.isEmpty) return false;
      try {
        final end = DateTime.parse(subscription.endDate);
        return DateTime.now().isAfter(end);
      } catch (_) {
        return false;
      }
    }();

    final statusColor = isExpired
        ? AppColors.warning
        : (isActive ? AppColors.success : AppColors.error);
    final statusBgColor = isExpired
        ? AppColors.warning.withOpacity(0.1)
        : (isActive
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1));
    final statusText = isExpired
        ? 'Expired'
        : (isActive ? 'Active' : 'Inactive');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: School Info & Status
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.business_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              school?.name ?? 'Unknown School',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: subscription.schoolId),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.schoolUuidCopied,
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ID: ${subscription.schoolId.length > 8 ? '${subscription.schoolId.substring(0, 8)}...' : subscription.schoolId}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: AppColors.primary.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              school?.email ?? 'No email',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (school?.phone != null &&
                          school!.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              school.phone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border.withOpacity(0.1)),

          // Body: Plan Details
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.lightGrey.withOpacity(0.5),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Plan',
                        plan?.name ?? 'N/A',
                        Icons.workspace_premium_rounded,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Students',
                        '${subscription.lastStudentCount} / ${plan?.maxStudents ?? '∞'}',
                        Icons.groups_rounded,
                        const Color(0xFF022B3A),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Monthly',
                        '\$${plan?.pricePerMonth ?? '0'}',
                        Icons.payments_rounded,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDateSection(
                        context,
                        'Start Date',
                        _formatDate(subscription.startDate),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: AppColors.border.withOpacity(0.2),
                      ),
                      _buildDateSection(
                        context,
                        'End Date',
                        _formatDate(subscription.endDate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border.withOpacity(0.1)),

          // Footer: Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${_formatDate(subscription.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
                Row(
                  children: [
                    if (!isExpired)
                      _ActionButton(
                        icon: isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        label: isActive ? 'Deactivate' : 'Activate',
                        color: isActive ? AppColors.warning : AppColors.success,
                        onTap: () => _updateStatus(context, !isActive),
                      ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: AppColors.error,
                      onTap: () => _confirmDelete(context),
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

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDateSection(BuildContext context, String label, String date) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(BuildContext context, bool newStatus) async {
    final success = await context
        .read<SubscriptionNotifier>()
        .updateSubscriptionStatus(subscription.id, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Status updated successfully' : 'Failed to update status',
            style: const TextStyle(color: AppColors.white),
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteSubscription),
        content: const Text(
          'Are you sure you want to delete this subscription? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await context
          .read<SubscriptionNotifier>()
          .deleteSubscription(subscription.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Subscription deleted successfully'
                  : 'Failed to delete subscription',
              style: const TextStyle(color: AppColors.white),
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
