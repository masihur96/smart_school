import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/utils/image_compress_utils.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/features/admin/providers/school_provider.dart';
import 'package:smart_school/features/admin/screens/onboarding_progress_screen.dart';
import 'package:smart_school/features/auth/presntation/views/login_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';

// ─── Brand Colors ─────────────────────────────────────────────────────────────
const _kPurple = Color(0xFF6C3CE1);
const _kPurpleLight = Color(0xFF9B6DFF);
const _kPurpleSoft = Color(0xFFF3EFFF);

// ═════════════════════════════════════════════════════════════════════════════
//  AdminRegisterSchoolScreen
// ═════════════════════════════════════════════════════════════════════════════
class AdminRegisterSchoolScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialPhone;

  const AdminRegisterSchoolScreen({
    super.key,
    this.initialEmail,
    this.initialPhone,
  });

  @override
  State<AdminRegisterSchoolScreen> createState() =>
      _AdminRegisterSchoolScreenState();
}

class _AdminRegisterSchoolScreenState
    extends State<AdminRegisterSchoolScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  File? _logoFile;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _getEmail(AuthNotifier authNotifier) {
    if (widget.initialEmail != null && widget.initialEmail!.trim().isNotEmpty) {
      return widget.initialEmail!.trim();
    }
    return authNotifier.user?.email.trim() ?? '';
  }

  String _getPhone(AuthNotifier authNotifier) {
    if (widget.initialPhone != null && widget.initialPhone!.trim().isNotEmpty) {
      return widget.initialPhone!.trim();
    }
    return authNotifier.user?.phone?.trim() ?? '';
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogoPickerSheet(),
    );
    if (source != null) {
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file != null) {
        final File compressed =
            await ImageCompressUtils.compressToUnder50KB(File(file.path));
        setState(() => _logoFile = compressed);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = context.read<AuthNotifier>();
    final schoolNotifier = context.read<AdminSchoolNotifier>();
    final schoolId = authNotifier.user?.schoolId;

    if (schoolId == null || schoolId.isEmpty) {
      if (mounted) {
        _showErrorSnackBar(
          AppLocalizations.of(context)?.errorNoSchoolIdAssigned ??
              'No school ID found. Please log in again.',
        );
      }
      return;
    }

    var email = _getEmail(authNotifier);
    if (email.isEmpty) email = await StorageService.getEmail() ?? '';
    final phone = _getPhone(authNotifier);

    final success = await schoolNotifier.registerSchool(
          schoolId: schoolId,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: phone,
          email: email,
          logoFile: _logoFile,
        );

    if (!mounted) return;
    if (success) {
      _showSuccessSnackBar(
        AppLocalizations.of(context)?.schoolRegisteredSuccessfully ??
            'School registered successfully!',
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingProgressScreen()),
      );
    } else if (mounted) {
      final error = schoolNotifier.error;
      _showErrorSnackBar(
        error ??
            AppLocalizations.of(context)?.failedToRegisterSchool ??
            'Failed to register school',
      );
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdminSchoolNotifier>().isLoading;
    final authNotifier = context.watch<AuthNotifier>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = _getEmail(authNotifier);
    final phone = _getPhone(authNotifier);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13111C) : const Color(0xFFF8F7FF),
      body: Column(
        children: [
          // ── Gradient Header ──
          _buildGradientHeader(context, authNotifier),

          // ── Scrollable Form ──
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo picker
                        _buildLogoSection(isDark),
                        const SizedBox(height: 28),

                        // Form fields card
                        _buildFormCard(isDark),
                        const SizedBox(height: 16),

                        // Contact preview
                        if (email.isNotEmpty || phone.isNotEmpty)
                          _buildContactPreview(email, phone, isDark),

                        const SizedBox(height: 28),

                        // Submit
                        _buildSubmitButton(isLoading),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient Header ───────────────────────────────────────────────────────
  Widget _buildGradientHeader(
      BuildContext context, AuthNotifier authNotifier) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A1FA8), _kPurple, _kPurpleLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                children: [
                  // Back / Logout
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white, size: 22),
                    tooltip: AppLocalizations.of(context)?.logOut ?? 'Log out',
                    onPressed: () async {
                      await authNotifier.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const Spacer(),
                  // Step badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text(
                      'STEP 1 OF 2',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School Profile',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tell us about your institution',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Progress stepper
              _buildProgressStepper(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStepper() {
    final steps = [
      ('School Info', Icons.business_rounded, true),
      ('Auto Setup', Icons.auto_fix_high_rounded, false),
    ];

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepperDot(
            label: steps[i].$1,
            icon: steps[i].$2,
            isActive: steps[i].$3,
            index: i + 1,
          ),
          if (i < steps.length - 1) _StepperLine(isCompleted: false),
        ]
      ],
    );
  }

  // ── Logo Section ──────────────────────────────────────────────────────────
  Widget _buildLogoSection(bool isDark) {
    return Column(
      children: [
        Text(
          'School Logo',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF1A1035),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Optional — adds branding to reports & cards',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _pickLogo,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main circle
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF1E1A2E)
                        : _kPurpleSoft,
                    border: Border.all(
                      color: _kPurple.withValues(alpha: 0.35),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kPurple.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _logoFile != null
                        ? Image.file(_logoFile!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_rounded,
                                  size: 40,
                                  color: _kPurple.withValues(alpha: 0.75)),
                              const SizedBox(height: 4),
                              Text(
                                'Add Logo',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kPurple.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                // Edit badge
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kPurple,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark ? const Color(0xFF13111C) : Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kPurple.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _logoFile != null
                          ? Icons.edit_rounded
                          : Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Form Card ─────────────────────────────────────────────────────────────
  Widget _buildFormCard(bool isDark) {
    final cardBg =
        isDark ? const Color(0xFF1C1829) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : _kPurple.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── School Name ──
          _FieldLabel('School Name', Icons.business_rounded, isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: AppLocalizations.of(context)!.egOxfordModel,
            icon: Icons.business_rounded,
            isDark: isDark,
            action: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return AppLocalizations.of(context)?.requiredField ??
                    'Please enter school name';
              }
              if (v.trim().length < 3) {
                return 'School name must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ── School Address ──
          _FieldLabel('School Address', Icons.location_on_rounded, isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _addressController,
            hint: AppLocalizations.of(context)!.egAddress,
            icon: Icons.location_on_rounded,
            isDark: isDark,
            maxLines: 2,
            action: TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return AppLocalizations.of(context)?.requiredField ??
                    'Please enter school address';
              }
              if (v.trim().length < 4) {
                return 'Address must be at least 4 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required String? Function(String?) validator,
    TextInputAction action = TextInputAction.next,
    int maxLines = 1,
  }) {
    final fillColor =
        isDark ? const Color(0xFF13111C) : const Color(0xFFF8F7FF);
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : _kPurple.withValues(alpha: 0.12);

    return TextFormField(
      controller: controller,
      textInputAction: action,
      maxLines: maxLines,
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF1A1035),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          fontSize: 13,
          color: isDark ? Colors.white30 : Colors.grey[400],
        ),
        prefixIcon: Padding(
          padding: maxLines > 1
              ? const EdgeInsets.only(bottom: 24)
              : EdgeInsets.zero,
          child: Icon(icon, color: _kPurple, size: 20),
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPurple, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.red.shade400, width: 1.8),
        ),
      ),
      validator: validator,
    );
  }

  // ── Contact Preview ───────────────────────────────────────────────────────
  Widget _buildContactPreview(String email, String phone, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kPurple.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _kPurple.withValues(alpha: isDark ? 0.25 : 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPurple.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: _kPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Principal Contact Linked',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.purple[200] : Colors.purple[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (email.isNotEmpty) email,
                    if (phone.isNotEmpty) phone,
                  ].join(' • '),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF10B981), size: 20),
        ],
      ),
    );
  }

  // ── Submit Button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: isLoading
              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
              : const LinearGradient(
                  colors: [Color(0xFF4A1FA8), _kPurple, _kPurpleLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: _kPurple.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.registerSchoolAction ??
                          'REGISTER SCHOOL',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Stepper Dot
// ═════════════════════════════════════════════════════════════════════════════
class _StepperDot extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final int index;

  const _StepperDot({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? _kPurple : Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight:
                isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StepperLine extends StatelessWidget {
  final bool isCompleted;
  const _StepperLine({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Field Label Helper
// ═════════════════════════════════════════════════════════════════════════════
class _FieldLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isDark;

  const _FieldLabel(this.text, this.icon, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _kPurple),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF1A1035),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Logo Picker Bottom Sheet
// ═════════════════════════════════════════════════════════════════════════════
class _LogoPickerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1829) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Upload School Logo',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1035),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you\'d like to add your logo',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          _SheetOption(
            icon: Icons.photo_library_rounded,
            label: 'Choose from Gallery',
            subtitle: 'Select from your photos',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 10),
          _SheetOption(
            icon: Icons.camera_alt_rounded,
            label: 'Take a Photo',
            subtitle: 'Use your camera',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : _kPurpleSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _kPurple.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _kPurple, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1035),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _kPurple, size: 20),
          ],
        ),
      ),
    );
  }
}
