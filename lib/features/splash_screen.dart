import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/admin/screens/admin_pricing_plan_screen.dart';
import 'package:smart_school/features/admin/screens/register_school_screen.dart';
import 'package:smart_school/features/auth/presntation/views/login_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/student/screens/student_dashboard_screen.dart';
import 'package:smart_school/features/super_admin/screens/super_admin_dashboard_screen.dart';
import 'package:smart_school/features/teacher/screens/teacher_dashboard_screen.dart';
import 'package:smart_school/models/user_model.dart';
import 'package:smart_school/services/app_update_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Run the update check concurrently with the branding delay so it adds
    // no extra latency in the common (no-update) case.
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _checkForAppUpdate(),
    ]);

    if (!mounted) return;

    final authNotifier = context.read<AuthNotifier>();
    await authNotifier.checkAuthStatus();

    if (!mounted) return;

    final user = authNotifier.user;
    if (user != null) {
      switch (user.role) {
        case UserRole.admin:
          if (user.school == null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => AdminRegisterSchoolScreen(
                  initialEmail: user.email,
                  initialPhone: user.phone,
                ),
              ),
              (Route<dynamic> route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => authNotifier.isSubscriptionValid
                    ? const AdminDashboardScreen()
                    : const AdminPricingPlanScreen(),
              ),
              (Route<dynamic> route) => false,
            );
          }
          break;
        case UserRole.teacher:
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => authNotifier.isSubscriptionValid
                  ? const TeacherDashboardScreen()
                  : const AdminPricingPlanScreen(),
            ),
            (Route<dynamic> route) => false,
          );
          break;
        case UserRole.student:
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => StudentDashboardScreen()),
            (Route<dynamic> route) => false,
          );
          break;
        case UserRole.superadmin:
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => SuperAdminDashboardScreen(),
            ),
            (Route<dynamic> route) => false,
          );
          break;
      }
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  /// Triggers an in-app update check. Immediate updates block here until
  /// the user completes the update; flexible updates will show a SnackBar
  /// after navigation (via the mounted context check inside the service).
  Future<void> _checkForAppUpdate() async {
    // checkAndHandleUpdate is a no-op on non-Android platforms and on
    // debug/sideloaded builds, so it's safe to call unconditionally.
    await AppUpdateService.instance.checkAndHandleUpdate(
      context,
      staleDaysThreshold: 5, // treat as immediate after 5 days of staleness
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: Image.asset(
                      "assets/icon/icon.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _opacityAnimation,
              child: Text(
                'SchoolCare',
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,

                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _opacityAnimation,
              child: Text(
                'Excellence in Education',
                style: GoogleFonts.outfit(fontSize: 16, letterSpacing: 1.5),
              ),
            ),
            Spacer(),

            FadeTransition(
              opacity: _opacityAnimation,
              child: const Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'STAY TUNED',
                    style: TextStyle(fontSize: 12, letterSpacing: 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }


}
