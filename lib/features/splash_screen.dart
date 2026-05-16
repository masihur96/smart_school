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
    // _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Ensuring animation plays for at least 2 seconds for branding
    await Future.delayed(const Duration(seconds: 2));

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
                builder: (context) => const AdminRegisterSchoolScreen(),
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
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
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

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
