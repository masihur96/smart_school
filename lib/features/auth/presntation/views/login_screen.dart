import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/utils/biometric_service.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/admin/screens/admin_pricing_plan_screen.dart';
import 'package:smart_school/features/admin/screens/register_school_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/student/screens/student_dashboard_screen.dart';
import 'package:smart_school/features/super_admin/screens/super_admin_dashboard_screen.dart';
import 'package:smart_school/features/teacher/screens/teacher_dashboard_screen.dart';
import 'package:smart_school/models/user_model.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _canUseBiometrics = false;
  bool _isBiometricLoading = false;

  /// Guards against double-navigation if build() fires multiple times
  /// while the subscription retry is in-flight.
  bool _isNavigating = false;

  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometrics());
  }

  Future<void> _checkBiometrics() async {
    final email = await StorageService.getEmail();
    final password = await StorageService.getPassword();
    if (email != null && password != null) {
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (mounted) setState(() => _canUseBiometrics = isAvailable);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Navigation ────────────────────────────────────────────────────────────
  // Called reactively from build() via addPostFrameCallback every time
  // authNotifier.user becomes non-null. This works even when the widget was
  // recreated during the biometric overlay (the classic !mounted early-return
  // bug), because navigation is driven by watched state, not the async callsite.

  Future<void> _navigateToDashboard(AuthNotifier authNotifier) async {
    if (_isNavigating) return;
    if (authNotifier.user == null) return;
    _isNavigating = true;

    // If subscription wasn't fetched (network blip during biometric overlay),
    // retry once before deciding which screen to open.
    final role = authNotifier.user!.role;
    if ((role == UserRole.admin || role == UserRole.teacher) &&
        authNotifier.adminSubscription == null) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await authNotifier.refreshSubscription();
      if (!mounted) return;
    }

    Widget dashboard;
    switch (role) {
      case UserRole.admin:
        if (authNotifier.user!.school == null) {
          dashboard = const AdminRegisterSchoolScreen();
        } else {
          dashboard = authNotifier.isSubscriptionValid
              ? const AdminDashboardScreen()
              : const AdminPricingPlanScreen();
        }
        break;
      case UserRole.teacher:
        dashboard = authNotifier.isSubscriptionValid
            ? const TeacherDashboardScreen()
            : const AdminPricingPlanScreen();
        break;
      case UserRole.student:
        dashboard = const StudentDashboardScreen();
        break;
      case UserRole.superadmin:
        dashboard = const SuperAdminDashboardScreen();
        break;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
    );
  }

  // ─── Login (email + password) ───────────────────────────────────────────────
  // Does NOT navigate — navigation is handled reactively in build().

  Future<void> _login() async {
    final authNotifier = context.read<AuthNotifier>();
    await authNotifier.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    // Save credentials for future biometric logins.
    // We do this outside the mounted check so it always runs.
    if (authNotifier.user != null) {
      await StorageService.saveEmail(_emailController.text.trim());
      await StorageService.savePassword(_passwordController.text);
    }
    // Navigation is triggered by build() watching authNotifier.user.
  }

  // ─── Biometric login ────────────────────────────────────────────────────────

  Future<void> _biometricLogin() async {
    if (_isBiometricLoading) return;
    if (!mounted) return;

    context.read<AuthNotifier>().clearError();
    setState(() => _isBiometricLoading = true);

    try {
      final authenticated = await _biometricService.authenticate();

      if (authenticated) {
        final email = await StorageService.getEmail();
        final password = await StorageService.getPassword();

        if (email != null && password != null) {
          // Directly call provider login — credentials are already stored,
          // no need to re-save. Navigation is reactive via build().
          await context.read<AuthNotifier>().login(email, password);
        } else {
          // Credentials were cleared from secure storage — fall back to manual.
          if (mounted) {
            setState(() => _canUseBiometrics = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Biometric credentials expired. Please log in manually.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Reactive navigation: fires whenever user becomes non-null,
      // regardless of which code path triggered the login.
      if (authNotifier.user != null && !authNotifier.isLoading) {
        _navigateToDashboard(authNotifier);
      }

      // Show error snackbar
      if (authNotifier.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authNotifier.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
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
              const SizedBox(height: 16),
              Text(
                'SchoolCare',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back! Please login to continue.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email or Phone',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: authNotifier.isLoading ? null : _login,
                      child: (authNotifier.isLoading && !_isBiometricLoading)
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Login',
                              style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  if (_canUseBiometrics) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: _isBiometricLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5),
                            )
                          : IconButton(
                              onPressed: authNotifier.isLoading
                                  ? null
                                  : _biometricLogin,
                              icon: const Icon(Icons.fingerprint, size: 40),
                              tooltip: 'Login with biometrics',
                            ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6750A4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLoginButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickLoginButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
