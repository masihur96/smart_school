import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/student/screens/student_dashboard_screen.dart';
import 'package:smart_school/features/teacher/screens/teacher_dashboard_screen.dart';
import 'package:smart_school/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _controller.forward();
    _checkAuth();
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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
                (Route<dynamic> route) => false,
          );
          break;
        case UserRole.teacher:
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => TeacherDashboardScreen()),
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
      }
    } else {
      context.go('/login');
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E), // Deep midnight blue
              Color(0xFF16213E), // Dark Navy
              Color(0xFF0F3460), // Royal blue touch
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Decorative Circles
            Positioned(
              top: -100,
              right: -100,
              child: _buildDecorativeCircle(200, Colors.white.withValues(alpha: 0.03)),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: _buildDecorativeCircle(150, Colors.white.withValues(alpha: 0.02)),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 80,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: Text(
                    'Smart School',
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              bottom: 60,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: const Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'STAY TUNED',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
