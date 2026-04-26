import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/super_admin/models/pricing_plan_model.dart';
import 'package:smart_school/features/super_admin/providers/pricing_notifier.dart';
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
    final authNotifier = context.watch<AuthNotifier>();
    final pricingNotifier = context.watch<PricingNotifier>();
    final subscription = authNotifier.adminSubscription;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildStatusBanner(authNotifier)),
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
                    const Text('No pricing plans available'),
                    TextButton(
                      onPressed: () => pricingNotifier.fetchPricingPlans(),
                      child: const Text('Retry'),
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
                  return _AdminPricingPlanCard(plan: plan);
                }, childCount: pricingNotifier.plans.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      flexibleSpace: const FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Subscription Required',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            await context.read<AuthNotifier>().logout();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatusBanner(AuthNotifier auth) {
    final sub = auth.adminSubscription;
    final isValid = auth.isSubscriptionValid;

    String title = 'No Active Subscription';
    String message =
        'Your institution needs an active plan to access the dashboard.';
    Color color = Colors.red;
    IconData icon = Icons.warning_amber_rounded;

    if (isValid && sub != null) {
      title = 'Active Subscription';
      message =
          'Your institution is on the ${sub.pricingPlan?.name ?? 'Standard'} plan, valid until ${sub.endDate.split('T')[0]}.';
      color = Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (sub != null && !isValid) {
      title = 'Subscription Expired';
      message =
          'Your plan expired on ${sub.endDate.split('T')[0]}. Please renew to continue.';
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminPricingPlanCard extends StatelessWidget {
  final PricingPlan plan;

  const _AdminPricingPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.primarySoft, width: 1.5),
      ),
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
                      plan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (plan.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CUSTOM',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  plan.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFeature(
                      Icons.people_outline,
                      '${plan.maxStudents} Students',
                    ),
                    _buildFeature(
                      Icons.calendar_today_outlined,
                      plan.pricePerMonth == "0"
                          ? "Weekly Billing"
                          : 'Monthly Billing',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      '\$${plan.pricePerMonth}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      plan.pricePerMonth == "0" ? ' / week' : ' / month',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              final auth = context.read<AuthNotifier>();
              final isFree =
                  plan.pricePerMonth == '0' ||
                  plan.name.toLowerCase().contains('free');

              final success = await auth.assignPricingPlan(plan.id!, isFree);

              if (success && context.mounted) {
                if (isFree) {
                  // Direct navigation for Free plans as they are auto-activated
                  if (auth.isSubscriptionValid) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } else {
                  // Show professional success dialog for paid plans
                  _showSuccessDialog(context, auth, plan);
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(auth.error ?? 'Failed to assign plan'),
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: Text(
                  'CHOOSE THIS PLAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
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
      builder: (context) => AlertDialog(
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
                  const Text(
                    'Perfect Choice!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You have successfully registered for the ${plan.name} plan. To activate your account, a request needs to be sent to our administration team.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _sendRequestEmail(auth, plan);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Activation request sent successfully. You will receive a confirmation email within 12 hours.',
                          ),
                          backgroundColor: Colors.green,
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
                    child: const Text('SEND ACTIVATION REQUEST'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Decide Later',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
