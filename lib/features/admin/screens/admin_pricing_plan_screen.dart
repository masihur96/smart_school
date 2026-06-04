import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/custom_size.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/super_admin/models/pricing_plan_model.dart';
import 'package:smart_school/features/super_admin/providers/pricing_notifier.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/presntation/views/login_screen.dart';

class AdminPricingPlanScreen extends StatefulWidget {
  const AdminPricingPlanScreen({super.key});

  @override
  State<AdminPricingPlanScreen> createState() => _AdminPricingPlanScreenState();
}

class _AdminPricingPlanScreenState extends State<AdminPricingPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PricingNotifier>().fetchPricingPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authNotifier = context.watch<AuthNotifier>();
    final pricingNotifier = context.watch<PricingNotifier>();
    final subscription = authNotifier.adminSubscription;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(l10n),
          SliverToBoxAdapter(child: _buildStatusBanner(authNotifier, l10n)),
          if (pricingNotifier.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (pricingNotifier.plans.isEmpty)
            SliverFillRemaining(
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final plan = pricingNotifier.plans[index];

                  final isPlanFree =
                      plan.pricePerMonth == '0' ||
                      plan.name.toLowerCase().contains('free');
                  final isSubscriptionExpired =
                      subscription != null && !authNotifier.isSubscriptionValid;

                  // Hide free plan cards when any current plan is expired
                  if (isPlanFree && isSubscriptionExpired) {
                    return const SizedBox.shrink();
                  }

                  return _AdminPricingPlanCard(
                    plan: plan,
                    currentCount: subscription?.lastStudentCount ?? 0,
                    isActive: subscription?.pricingPlan?.id == plan.id,
                    isAlreadyUsedFreePlan: false,
                  );
                }, childCount: pricingNotifier.plans.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 60,
      pinned: true,
      backgroundColor: AppColors.primaryAdmin,

      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          l10n.subscriptionRequired,
          style: TextStyle(
            fontSize: screenSize(context, .04),
            color: AppColors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
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
    );
  }

  String formatDate(String? utcDate) {
    if (utcDate == null || utcDate.isEmpty) {
      return '--';
    }

    final localDate = DateTime.parse(utcDate).toLocal();

    return DateFormat('dd MMM yyyy').format(localDate);
  }

  Widget _buildStatusBanner(AuthNotifier auth, AppLocalizations l10n) {
    final sub = auth.adminSubscription;
    final isValid = auth.isSubscriptionValid;

    String title = l10n.noActiveSubscription;
    String message = l10n.noActiveSubscriptionDesc;
    Color color = Colors.red;
    IconData icon = Icons.warning_amber_rounded;

    if (isValid && sub != null) {
      title = l10n.activeSubscription;
      message = l10n.activeSubscriptionDesc(
        sub.pricingPlan?.name ?? 'Standard',
        formatDate(sub.endDate),
      );
      color = AppColors.primaryAdmin;
      icon = Icons.check_circle_rounded;
    } else if (sub != null && !isValid) {
      title = l10n.subscriptionExpired;
      message = l10n.subscriptionExpiredDesc(sub.endDate.split('T')[0]);
    }

    return Card(
      margin: EdgeInsets.all(16),
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
              style: TextStyle(fontSize: 14),
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

  const _AdminPricingPlanCard({
    required this.plan,
    required this.currentCount,
    required this.isActive,
    this.isAlreadyUsedFreePlan = false,
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
                      '\$${widget.plan.pricePerMonth}',
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
                    setState(() {
                      _isLoading = true;
                    });
                    final auth = context.read<AuthNotifier>();
                    final isFree =
                        widget.plan.pricePerMonth == '0' ||
                        widget.plan.name.toLowerCase().contains('free');

                    final success = await auth.assignPricingPlan(
                      widget.plan.id!,
                      isFree,
                    );

                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }

                    if (success && context.mounted) {
                      if (isFree) {
                        // Direct navigation for Free plans as they are auto-activated
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
                      } else {
                        // Show professional success dialog for paid plans
                        _showSuccessDialog(context, auth, widget.plan);
                      }
                    } else if (context.mounted) {
                      final l10n = AppLocalizations.of(context)!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(auth.error ?? l10n.failedToAssignPlan),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
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

  void _showSuccessDialog(
    BuildContext context,
    AuthNotifier auth,
    PricingPlan plan,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                        _sendRequestEmail(auth, plan);
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

  Future<void> _sendRequestEmail(AuthNotifier auth, PricingPlan plan) async {
    final user = auth.user;
    final String subject = Uri.encodeComponent(
      'Plan Activation Request: ${plan.name}',
    );
    final String body = Uri.encodeComponent(
      'Hello Admin,\n\n'
      'I have selected the ${plan.name} plan for my school.\n'
      'Please accept my registration and activate the plan.\n\n'
      'User Details:\n'
      'Name: ${user?.name}\n'
      'Email: ${user?.email}\n'
      'School ID: ${user?.schoolId}\n\n'
      'Regards,\n'
      '${user?.name}',
    );

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
