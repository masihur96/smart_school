import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/sms_provider.dart';
import 'package:smart_school/features/admin/widgets/sms_buy_sheet.dart';
import 'package:smart_school/models/sms_models.dart';

class SmsQuotaPackagesTab extends StatelessWidget {
  const SmsQuotaPackagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final smsProvider = context.watch<SmsProvider>();
    final quota = smsProvider.quotaStatus;
    final packages = smsProvider.packages;
    final isLoading =
        smsProvider.isLoadingQuota || smsProvider.isLoadingPackages;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          smsProvider.fetchQuotaStatus(),
          smsProvider.fetchPackages(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 1. Quota Summary Card ──────────────────────────────────────────
          _buildQuotaCard(context, quota, isLoading, isDark),
          const SizedBox(height: 16),

          // ── 2. Low Balance Alert (if low) ──────────────────────────────────
          if (quota != null && (quota.isLowBalance || quota.balance < 50)) ...[
            _buildLowBalanceBanner(context, quota, isDark),
            const SizedBox(height: 16),
          ],

          // ── 3. Packages Header ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: 18,
                    color: AppColors.primaryAdmin,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SMS Recharge Bundles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => SmsBuySheet.show(context),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                label: const Text('Custom Buy'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryAdmin,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── 4. Packages List ───────────────────────────────────────────────
          if (packages.isEmpty && smsProvider.isLoadingPackages)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (packages.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('No SMS packages found currently.'),
              ),
            )
          else
            ...packages.map((pkg) => _buildPackageCard(context, pkg, isDark)),

          const SizedBox(height: 20),

          // ── 5. Recent Quota Transactions ───────────────────────────────────
          if (quota != null && quota.recentTransactions.isNotEmpty) ...[
            const Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: Colors.blueGrey,
                ),
                SizedBox(width: 8),
                Text(
                  'Recent Balance Activity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTransactionsCard(context, quota.recentTransactions, isDark),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotaCard(
    BuildContext context,
    SmsQuotaStatus? quota,
    bool isLoading,
    bool isDark,
  ) {
    final balance = quota?.balance ?? 0;
    final totalPurchased = quota?.totalPurchased ?? 0;
    final totalUsed = quota?.totalUsed ?? 0;
    final schoolName = quota?.schoolName ?? 'School Care';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryAdmin,
            AppColors.primaryAdmin.withValues(alpha: 0.85),
            const Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAdmin.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  schoolName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (quota?.isEnabled ?? true)
                      ? Colors.green.withValues(alpha: 0.25)
                      : Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (quota?.isEnabled ?? true)
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: (quota?.isEnabled ?? true)
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      (quota?.isEnabled ?? true) ? 'Active' : 'Disabled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Available SMS Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                NumberFormat.decimalPattern().format(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Credits',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => SmsBuySheet.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryAdmin,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: const Text(
                  'Top-up',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Purchased', '$totalPurchased'),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                _buildStatColumn('Used', '$totalUsed'),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                _buildStatColumn(
                  'Low Threshold',
                  '${quota?.lowBalanceThreshold ?? 50}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLowBalanceBanner(
    BuildContext context,
    SmsQuotaStatus quota,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade700, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low SMS Balance Warning',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.amber.shade800,
                  ),
                ),
                Text(
                  'Your balance is below ${quota.lowBalanceThreshold} credits. Top up soon to avoid delivery pauses.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => SmsBuySheet.show(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Top Up'),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    SmsPackage pkg,
    bool isDark,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: pkg.isPopular
              ? AppColors.primaryAdmin
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: pkg.isPopular ? 1.8 : 1,
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Left Icon / SMS badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (pkg.isPopular ? Colors.amber : AppColors.primaryAdmin)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                pkg.isPopular
                    ? Icons.local_fire_department_rounded
                    : Icons.sms_rounded,
                color: pkg.isPopular ? Colors.amber.shade800 : AppColors.primaryAdmin,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Middle: Name & description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pkg.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (pkg.isPopular) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${NumberFormat.decimalPattern().format(pkg.smsCount)} SMS Credits',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (pkg.description != null && pkg.description!.isNotEmpty)
                    Text(
                      pkg.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  Text(
                    '৳${pkg.perSmsRate.toStringAsFixed(2)} per SMS',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right: Price & Buy button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳${pkg.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryAdmin,
                  ),
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () => SmsBuySheet.show(context, package: pkg),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAdmin,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Buy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
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

  Widget _buildTransactionsCard(
    BuildContext context,
    List<SmsTransaction> txns,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: txns.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
        itemBuilder: (context, idx) {
          final txn = txns[idx];
          final isUsage = txn.type == 'USAGE';
          final isPurchase = txn.type == 'PURCHASE';
          final isRefund = txn.type == 'REFUND';

          Color color = Colors.blueGrey;
          IconData icon = Icons.swap_horiz_rounded;
          String prefix = '';

          if (isUsage) {
            color = Colors.red;
            icon = Icons.arrow_outward_rounded;
            prefix = '';
          } else if (isPurchase) {
            color = Colors.green;
            icon = Icons.add_circle_outline_rounded;
            prefix = '+';
          } else if (isRefund) {
            color = Colors.teal;
            icon = Icons.replay_rounded;
            prefix = '+';
          }

          final dateStr = txn.createdAt != null
              ? DateFormat('dd MMM, hh:mm a').format(txn.createdAt!.toLocal())
              : '';

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 16, color: color),
            ),
            title: Text(
              txn.description ?? txn.type,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text(
              '$dateStr • Bal: ${txn.previousBalance} → ${txn.newBalance}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            trailing: Text(
              '$prefix${txn.amount}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}
