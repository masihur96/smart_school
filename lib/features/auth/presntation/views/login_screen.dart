import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/settings_provider.dart';
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
  bool _isGoogleLoading = false;

  /// Guards against double-navigation if build() fires multiple times
  /// while the subscription retry is in-flight.
  bool _isNavigating = false;

  final BiometricService _biometricService = BiometricService();

  String? _validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.pleaseEnterYourEmailOrPhoneNumber;
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
        return AppLocalizations.of(context)!.pleaseEnterAValidEmailAddress;
      } else if (RegExp(r'^[0-9+]').hasMatch(trimmed)) {
        return AppLocalizations.of(context)!.pleaseEnterAValidPhoneNumber;
      }
      return AppLocalizations.of(context)!.pleaseEnterAValidEmailOrPhoneNumber;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.pleaseEnterYourPassword;
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
        title: AppLocalizations.of(context)!.accountInactive,
        message:
            AppLocalizations.of(context)!.accountInactiveMessage,
      );
      return;
    }

    if (authNotifier.user?.school?.isActive == false) {
      await authNotifier.logout();
      _isNavigating = false;
      if (!mounted) return;
      _showInactiveDialog(
        title: AppLocalizations.of(context)!.schoolInactive,
        message:
            AppLocalizations.of(context)!.schoolInactiveMessage,
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
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.biometricCredentialsExpired,
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

  // ─── Google login ───────────────────────────────────────────────────────────

  Future<void> _googleLogin() async {
    final authNotifier = context.read<AuthNotifier>();
    if (_isGoogleLoading || authNotifier.isLoading) return;
    if (!mounted) return;

    authNotifier.clearError();
    setState(() => _isGoogleLoading = true);

    try {
      await authNotifier.loginWithGoogle();
      // Navigation is handled reactively by build() watching authNotifier.user.
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  static const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>
''';

  Widget _buildGoogleLogo() {
    return SvgPicture.string(
      _googleSvg,
      width: 22,
      height: 22,
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────


  Widget _buildLanguageDropdown(bool isDark) {
    final settings = context.watch<SettingsProvider>();
    return PopupMenuButton<String>(
      icon: Icon(Icons.language, color: isDark ? Colors.white : Colors.black87),
      onSelected: (String langCode) {
        settings.setLocale(Locale(langCode));
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'en',
          child: Text('English'),
        ),
        const PopupMenuItem<String>(
          value: 'bn',
          child: Text('বাংলা'),
        ),
      ],
    );
  }

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
        authNotifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
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
                          child: Text(
                            AppLocalizations.of(context)!.schoolcareDigitalCampus,
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
                          AppLocalizations.of(context)!.welcomeBack,
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
                          AppLocalizations.of(context)!.signInToManageYourSchool,
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
                        Text(
                          AppLocalizations.of(context)!.emailOrPhoneNumber,
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
                            hintText: AppLocalizations.of(context)!.egPrincipalContact,
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
                        Text(
                          AppLocalizations.of(context)!.password,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.enterYourPassword,
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
                          onPressed: (authNotifier.isLoading || _isGoogleLoading)
                              ? null
                              : _login,
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
                                  !_isBiometricLoading &&
                                  !_isGoogleLoading)
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
                                          AppLocalizations.of(context)!.logIn.toUpperCase(),
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
                                  onPressed: (authNotifier.isLoading || _isGoogleLoading)
                                      ? null
                                      : _biometricLogin,
                                  icon: const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 32,
                                    color: Colors.purple,
                                  ),
                                  tooltip: AppLocalizations.of(context)!.logInWithBiometrics,
                                ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── OR Divider ──────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? const Color(0xFF2C3242)
                              : Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          (Localizations.localeOf(context).languageCode == 'bn')
                              ? 'অথবা'
                              : 'OR',
                          style: TextStyle(
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? const Color(0xFF2C3242)
                              : Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Google Login Button ─────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: OutlinedButton(
                      onPressed: (authNotifier.isLoading || _isGoogleLoading)
                          ? null
                          : _googleLogin,
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            isDark ? const Color(0xFF1E222D) : Colors.white,
                        foregroundColor:
                            isDark ? Colors.white : const Color(0xFF2D3142),
                        disabledBackgroundColor: isDark
                            ? const Color(0xFF1E222D).withOpacity(0.6)
                            : Colors.white.withOpacity(0.6),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF333846)
                              : const Color(0xFFE2E4EB),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isGoogleLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.purple,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGoogleLogo(),
                                const SizedBox(width: 12),
                                Text(
                                  (Localizations.localeOf(context).languageCode ==
                                          'bn')
                                      ? 'গুগল দিয়ে সাইন ইন করুন'
                                      : 'Sign in with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF2D3142),
                                  ),
                                ),
                              ],
                            ),
                    ),
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
                          AppLocalizations.of(context)!.dontHaveAnAccount,
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
                          child: Text(
                            AppLocalizations.of(context)!.registerNow,
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
            Positioned(
              top: 8,
              right: 8,
              child: _buildLanguageDropdown(isDark),
            ),
          ],
        ),
      ),
    );
  }
}
