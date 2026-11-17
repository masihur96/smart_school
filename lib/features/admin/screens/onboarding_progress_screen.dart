import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/onboarding_provider.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';

// ─── Setup Step Model ────────────────────────────────────────────────────────
enum _StepStatus { waiting, active, done, error }

class _SetupStep {
  final String label;
  final IconData icon;
  _StepStatus status;
  _SetupStep({
    required this.label,
    required this.icon,
    _StepStatus initialStatus = _StepStatus.waiting,
  }) : status = initialStatus;
}

// ═════════════════════════════════════════════════════════════════════════════
//  OnboardingProgressScreen
// ═════════════════════════════════════════════════════════════════════════════
class OnboardingProgressScreen extends StatefulWidget {
  const OnboardingProgressScreen({super.key});

  @override
  State<OnboardingProgressScreen> createState() =>
      _OnboardingProgressScreenState();
}

class _OnboardingProgressScreenState extends State<OnboardingProgressScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerController;
  late final AnimationController _successController;
  bool _freePlanAssigning = false;

  late final List<_SetupStep> _steps;

  @override
  void initState() {
    super.initState();

    _steps = [
      _SetupStep(label: 'Initializing setup', icon: Icons.settings_rounded),
      _SetupStep(label: 'Creating classes', icon: Icons.class_rounded),
      _SetupStep(label: 'Adding sections', icon: Icons.tab_rounded),
      _SetupStep(label: 'Setting up subjects', icon: Icons.book_rounded),
      _SetupStep(
          label: 'Verifying subscription', icon: Icons.verified_rounded),
      _SetupStep(label: 'Finalizing your school', icon: Icons.school_rounded),
    ];

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      if (user?.schoolId != null) {
        context.read<OnboardingNotifier>().startOnboarding(user!.schoolId!);
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _successController.dispose();
    super.dispose();
  }

  /// Map progress (0–1) to step list statuses
  void _updateStepStatuses(double progress, bool hasError) {
    if (hasError) {
      for (int i = 0; i < _steps.length; i++) {
        if (_steps[i].status == _StepStatus.active) {
          _steps[i].status = _StepStatus.error;
        }
      }
      return;
    }

    // Distribute steps across progress
    final stepCount = _steps.length;
    for (int i = 0; i < stepCount; i++) {
      final stepThreshold = (i + 1) / stepCount;
      final prevThreshold = i / stepCount;
      if (progress >= stepThreshold) {
        _steps[i].status = _StepStatus.done;
      } else if (progress >= prevThreshold) {
        _steps[i].status = _StepStatus.active;
      } else {
        _steps[i].status = _StepStatus.waiting;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingNotifier>();
    final auth = context.read<AuthNotifier>();

    // Update steps
    _updateStepStatuses(onboarding.progress, onboarding.error != null);

    // Navigate when complete
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (onboarding.isCompleted &&
          !onboarding.isLoading &&
          !_freePlanAssigning) {
        _successController.forward();
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        if (auth.isSubscriptionValid) {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            (route) => false,
          );
        } else {
          _freePlanAssigning = true;
          await auth.autoAssignFreePlan();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            (route) => false,
          );
        }
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5B2D8E), Color(0xFF8B44CC), Color(0xFF6C3CE1)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Background decorations ──
              _BackgroundDecor(),

              // ── Main content ──
              SafeArea(
                child: onboarding.isCompleted
                    ? _buildSuccessView()
                    : _buildProgressView(onboarding, auth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Progress View ──────────────────────────────────────────────────────────
  Widget _buildProgressView(
      OnboardingNotifier onboarding, AuthNotifier auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // ── Animated header ──
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _headerController,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: _headerController,
              child: _buildHeader(onboarding),
            ),
          ),

          const SizedBox(height: 40),

          // ── Error view or progress steps ──
          Expanded(
            child: onboarding.error != null
                ? _buildErrorCard(onboarding, auth)
                : _buildStepsCard(onboarding),
          ),

          const SizedBox(height: 24),

          // ── Bottom hint ──
          if (onboarding.isLoading && onboarding.error == null)
            Column(
              children: [
                Text(
                  'Please keep the app open',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Setting up your school workspace...',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(OnboardingNotifier onboarding) {
    final percent = (onboarding.progress * 100).toInt();
    return Column(
      children: [
        // Icon
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: onboarding.error != null
              ? const Icon(Icons.error_outline_rounded,
                  size: 44, color: Colors.white)
              : _PulsingIcon(
                  icon: Icons.auto_awesome_rounded,
                  isActive: onboarding.isLoading,
                ),
        ),
        const SizedBox(height: 20),

        Text(
          onboarding.error != null
              ? 'Setup Encountered an Issue'
              : 'Setting Up Your School',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          onboarding.error != null
              ? 'Something went wrong. You can retry below.'
              : 'We\'re configuring everything for you',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 14,
            height: 1.4,
          ),
        ),

        if (onboarding.error == null) ...[
          const SizedBox(height: 28),
          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: onboarding.progress,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStepsCard(OnboardingNotifier onboarding) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Setup Steps',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (_, i) => _StepTile(step: _steps[i]),
            ),
          ),
          if (onboarding.statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        onboarding.statusMessage,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(
      OnboardingNotifier onboarding, AuthNotifier auth) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Setup Failed',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              onboarding.error ??
                  'An unexpected error occurred. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            // Retry button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final user = auth.user;
                  if (user?.schoolId != null) {
                    onboarding.reset();
                    for (final s in _steps) {
                      s.status = _StepStatus.waiting;
                    }
                    onboarding.startOnboarding(user!.schoolId!);
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  l10n.retrySetup,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6C3CE1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success View ───────────────────────────────────────────────────────────
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie success animation
            SizedBox(
              width: 180,
              height: 180,
              child: Lottie.asset(
                'assets/animation1.json',
                controller: _successController,
                onLoaded: (comp) {
                  _successController.duration = comp.duration;
                  _successController.forward();
                },
                repeat: false,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '🎉 All Done!',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your school workspace is ready.\nTaking you to the dashboard…',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Step Tile
// ═════════════════════════════════════════════════════════════════════════════
class _StepTile extends StatelessWidget {
  final _SetupStep step;
  const _StepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final Widget statusWidget;

    switch (step.status) {
      case _StepStatus.done:
        statusColor = const Color(0xFF10B981);
        statusWidget = const Icon(Icons.check_rounded,
            color: Colors.white, size: 14);
        break;
      case _StepStatus.active:
        statusColor = Colors.white;
        statusWidget = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF6C3CE1),
          ),
        );
        break;
      case _StepStatus.error:
        statusColor = Colors.red;
        statusWidget =
            const Icon(Icons.close_rounded, color: Colors.white, size: 14);
        break;
      case _StepStatus.waiting:
        statusColor = Colors.white.withValues(alpha: 0.25);
        statusWidget = const SizedBox.shrink();
    }

    final labelColor = step.status == _StepStatus.waiting
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: step.status == _StepStatus.active
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Status indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: statusWidget),
          ),
          const SizedBox(width: 14),

          // Icon
          Icon(
            step.icon,
            size: 18,
            color: labelColor,
          ),
          const SizedBox(width: 10),

          // Label
          Expanded(
            child: Text(
              step.label,
              style: GoogleFonts.outfit(
                color: labelColor,
                fontSize: 13,
                fontWeight: step.status == _StepStatus.active
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),

          // Active indicator text
          if (step.status == _StepStatus.active)
            Text(
              'In progress',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (step.status == _StepStatus.done)
            Text(
              'Done',
              style: GoogleFonts.outfit(
                color: const Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Pulsing Icon Widget
// ═════════════════════════════════════════════════════════════════════════════
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  const _PulsingIcon({required this.icon, required this.isActive});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Icon(widget.icon, size: 44, color: Colors.white);
    }
    return ScaleTransition(
      scale: _scale,
      child: Icon(widget.icon, size: 44, color: Colors.white),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Background Decoration
// ═════════════════════════════════════════════════════════════════════════════
class _BackgroundDecor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
      ],
    );
  }
}
