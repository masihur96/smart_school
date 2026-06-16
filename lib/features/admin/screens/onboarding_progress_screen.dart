import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/onboarding_provider.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';

class OnboardingProgressScreen extends StatefulWidget {
  const OnboardingProgressScreen({super.key});

  @override
  State<OnboardingProgressScreen> createState() =>
      _OnboardingProgressScreenState();
}

class _OnboardingProgressScreenState extends State<OnboardingProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      if (user?.schoolId != null) {
        context.read<OnboardingNotifier>().startOnboarding(user!.schoolId!);
      }
    });
  }

  bool _freePlanAssigning = false;

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingNotifier>();
    final auth = context.read<AuthNotifier>();

    // Use post-frame callback for navigation to avoid build issues
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (onboarding.isCompleted && !onboarding.isLoading && !_freePlanAssigning) {
        if (auth.isSubscriptionValid) {
          // Already has a valid subscription — go to dashboard
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              (route) => false,
            );
          }
        } else {
          // Auto-assign free plan then navigate to dashboard
          _freePlanAssigning = true;
          await auth.autoAssignFreePlan();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              (route) => false,
            );
          }
        }
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryAdmin,
              AppColors.primaryAdmin.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon / Illustration
                _buildAnimatedHeader(),
                const SizedBox(height: 60),

                // Title
                Text(
                  onboarding.error != null ? 'Setup Encountered an Issue' : 'Setting Up Your School',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Status Message
                Text(
                  onboarding.error ?? onboarding.statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 60),

                // Progress Bar
                if (onboarding.error == null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: onboarding.progress,
                      minHeight: 12,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(onboarding.progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ] else ...[
                  // Retry Button
                  ElevatedButton.icon(
                    onPressed: () {
                      final user = auth.user;
                      if (user?.schoolId != null) {
                        onboarding.startOnboarding(user!.schoolId!);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Setup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryAdmin,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 40),
                if (onboarding.isLoading)
                  Text(
                    'Please do not close the app...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 80,
        color: Colors.white,
      ),
    );
  }
}
