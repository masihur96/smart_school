import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/utils/biometric_service.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/admin/screens/admin_pricing_plan_screen.dart';
import 'package:smart_school/features/admin/screens/register_school_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/student/screens/student_dashboard_screen.dart';
import 'package:smart_school/features/super_admin/screens/super_admin_dashboard_screen.dart';
import 'package:smart_school/features/teacher/screens/teacher_dashboard_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/user_model.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _canUseBiometrics = false;
  bool _isBiometricLoading = false;

  /// Guards against double-navigation if build() fires multiple times
  /// while the subscription retry is in-flight.
  bool _isNavigating = false;

  final BiometricService _biometricService = BiometricService();

  String? _validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email or phone number';
    }

    final trimmed = value.trim();

    // Regular expression for validating email address
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    // Regular expression for validating phone number (e.g. +8801..., 01..., 10 to 15 digits)
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

    final cleanPhone = trimmed.replaceAll(RegExp(r'[\s-]'), '');
    final isEmail = emailRegex.hasMatch(trimmed);
    final isPhone = phoneRegex.hasMatch(cleanPhone);

    if (!isEmail && !isPhone) {
      if (trimmed.contains('@')) {
        return 'Please enter a valid email address';
      } else if (RegExp(r'^[0-9+]').hasMatch(trimmed)) {
        return 'Please enter a valid phone number';
      }
      return 'Please enter a valid email or phone number';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometrics());
  }

  Future<void> _checkBiometrics() async {
    final email = await StorageService.getEmail();
    final password = await StorageService.getPassword();
    final isBiometricEnabled = await StorageService.getBiometricEnabled();

    if (email != null && password != null && isBiometricEnabled) {
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

    if (authNotifier.user?.isActive == false) {
      await authNotifier.logout();
      _isNavigating = false;
      if (!mounted) return;
      _showInactiveDialog(
        title: 'Account Inactive',
        message:
            'Your account is currently inactive. Please communicate with your principal or administrator for assistance.',
      );
      return;
    }

    if (authNotifier.user?.school?.isActive == false) {
      await authNotifier.logout();
      _isNavigating = false;
      if (!mounted) return;
      _showInactiveDialog(
        title: 'School Inactive',
        message:
            'Your school account is currently inactive. Please communicate with SchoolCare support for assistance.',
      );
      return;
    }

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
          dashboard = AdminRegisterSchoolScreen(
            initialEmail: authNotifier.user?.email,
            initialPhone: authNotifier.user?.phone,
          );
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

  void _showInactiveDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  // ─── Login (email + password) ───────────────────────────────────────────────
  // Does NOT navigate — navigation is handled reactively in build().

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = context.read<AuthNotifier>();
    await authNotifier.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
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
                  'Biometric credentials expired. Please log in manually.',
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Branding Header Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E222D) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // App Icon with subtle glowing container
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.purple.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.15),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              "assets/icon/icon.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SCHOOLCARE DIGITAL CAMPUS',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome Back',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to manage your school and academic workspace.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Fields Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E222D) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email or Phone Label
                        const Text(
                          'Email or Phone Number',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'e.g. principal@school.edu or 017...',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Colors.purple,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF252A36)
                                : const Color(0xFFF9FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.purple,
                                width: 1.8,
                              ),
                            ),
                          ),
                          validator: _validateEmailOrPhone,
                        ),
                        const SizedBox(height: 16),

                        // Password Label
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.purple,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                () =>
                                    _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF252A36)
                                : const Color(0xFFF9FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.purple,
                                width: 1.8,
                              ),
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!authNotifier.isLoading) {
                              _login();
                            }
                          },
                          validator: _validatePassword,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button & Biometrics Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: authNotifier.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.purple.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                            shadowColor: Colors.purple.withOpacity(0.4),
                          ),
                          child: (authNotifier.isLoading &&
                                  !_isBiometricLoading)
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)
                                              ?.loginButton ??
                                          'LOG IN',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_canUseBiometrics) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E222D)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.purple.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: _isBiometricLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(14.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.purple,
                                  ),
                                )
                              : IconButton(
                                  onPressed: authNotifier.isLoading
                                      ? null
                                      : _biometricLogin,
                                  icon: const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 32,
                                    color: Colors.purple,
                                  ),
                                  tooltip: 'Log in with biometrics',
                                ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Don't have an account? Register Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E222D)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: const Text(
                            'Register Now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
