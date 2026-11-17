import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/onboarding_provider.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';

// ─── Setup Step Model ─────────────────────────────────────────────────────────
enum _StepStatus { waiting, active, done, error }

class _SetupStep {
  final String label;
  final String sublabel;
  final IconData icon;
  _StepStatus status;
  _SetupStep({
    required this.label,
    required this.sublabel,
    required this.icon,
    _StepStatus initialStatus = _StepStatus.waiting,
  }) : status = initialStatus;
}

// ─── Design constants ─────────────────────────────────────────────────────────
const _kPurple      = Color(0xFF6C3CE1);
const _kPurpleLight = Color(0xFF9B6DFF);
const _kGreen       = Color(0xFF10B981);
const _kBlue        = Color(0xFF0EA5E9);

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
  late final AnimationController _bgRotateCtrl;
  late final AnimationController _headerCtrl;
  late final AnimationController _successCtrl;
  late final AnimationController _lottieCtrl;
  bool _freePlanAssigning = false;
  bool _successStarted = false;

  late final List<_SetupStep> _steps;

  @override
  void initState() {
    super.initState();

    _steps = [
      _SetupStep(
        label: 'Initializing',
        sublabel: 'Preparing your workspace',
        icon: Icons.settings_rounded,
      ),
      _SetupStep(
        label: 'Creating Classes',
        sublabel: 'Class 1 through Class 5',
        icon: Icons.class_rounded,
      ),
      _SetupStep(
        label: 'Adding Sections',
        sublabel: 'Section A per class',
        icon: Icons.view_list_rounded,
      ),
      _SetupStep(
        label: 'Setting Up Subjects',
        sublabel: 'Bangla, English, Math & more',
        icon: Icons.menu_book_rounded,
      ),
      _SetupStep(
        label: 'Verifying Subscription',
        sublabel: 'Checking your plan',
        icon: Icons.verified_rounded,
      ),
      _SetupStep(
        label: 'Finalizing School',
        sublabel: 'Almost there!',
        icon: Icons.school_rounded,
      ),
    ];

    _bgRotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _lottieCtrl = AnimationController(vsync: this);

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
    _bgRotateCtrl.dispose();
    _headerCtrl.dispose();
    _successCtrl.dispose();
    _lottieCtrl.dispose();
    super.dispose();
  }

  void _updateStepStatuses(double progress, bool hasError) {
    if (hasError) {
      for (final s in _steps) {
        if (s.status == _StepStatus.active) s.status = _StepStatus.error;
      }
      return;
    }
    final count = _steps.length;
    for (int i = 0; i < count; i++) {
      final top = (i + 1) / count;
      final bot = i / count;
      if (progress >= top) {
        _steps[i].status = _StepStatus.done;
      } else if (progress >= bot) {
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
    _updateStepStatuses(onboarding.progress, onboarding.error != null);

    // Navigate on completion
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (onboarding.isCompleted && !onboarding.isLoading && !_freePlanAssigning) {
        if (!_successStarted) {
          _successStarted = true;
          _successCtrl.forward();
        }
        await Future.delayed(const Duration(milliseconds: 2000));
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
        backgroundColor: const Color(0xFF0F0A1E),
        body: Stack(
          children: [
            // ── Animated rotating mesh background ──
            _RotatingMesh(controller: _bgRotateCtrl),

            // ── Main scrollable content ──
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: onboarding.isCompleted
                    ? _buildSuccessView(key: const ValueKey('success'))
                    : _buildProgressView(
                        onboarding, auth, key: const ValueKey('progress')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Progress View
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProgressView(
    OnboardingNotifier onboarding,
    AuthNotifier auth, {
    Key? key,
  }) {
    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── App icon header ──
          FadeTransition(
            opacity: _headerCtrl,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.15),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _headerCtrl,
                curve: Curves.easeOutCubic,
              )),
              child: _buildAppHeader(onboarding),
            ),
          ),

          const SizedBox(height: 32),

          // ── Progress arc ──
          if (onboarding.error == null)
            FadeTransition(
              opacity: _headerCtrl,
              child: _CircularProgress(value: onboarding.progress),
            ),

          const SizedBox(height: 32),

          // ── Steps or error ──
          onboarding.error != null
              ? _buildErrorCard(onboarding, auth)
              : _buildStepsCard(onboarding),
        ],
      ),
    );
  }

  Widget _buildAppHeader(OnboardingNotifier onboarding) {
    final percent = (onboarding.progress * 100).toInt();
    return Column(
      children: [
        // App icon with glow
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kPurpleLight.withValues(alpha: 0.4),
                    _kPurple.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // App icon
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/icon/icon.png',
                width: 76,
                height: 76,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          onboarding.error != null
              ? 'Setup Encountered an Issue'
              : 'Setting Up Your School',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          onboarding.error != null
              ? 'Something went wrong. You can retry below.'
              : onboarding.statusMessage.isNotEmpty
                  ? onboarding.statusMessage
                  : 'Configuring your workspace automatically…',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            height: 1.5,
          ),
        ),

        if (onboarding.error == null && onboarding.isLoading) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              '$percent% complete',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepsCard(OnboardingNotifier onboarding) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: _kPurpleLight,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Auto Configuration',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
            child: Text(
              'We\'re setting up default classes, sections and subjects',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ),

          // Divider
          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),

          // Steps list
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: _steps
                  .asMap()
                  .entries
                  .map((e) => _StepTile(
                        step: e.value,
                        index: e.key,
                        total: _steps.length,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(OnboardingNotifier onboarding, AuthNotifier auth) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Setup Failed',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            onboarding.error ?? 'An unexpected error occurred.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
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
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                l10n.retrySetup,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _kPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Success View
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSuccessView({Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie animation
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animation1.json',
                controller: _lottieCtrl,
                onLoaded: (comp) {
                  _lottieCtrl.duration = comp.duration;
                  _lottieCtrl.forward();
                },
                repeat: false,
              ),
            ),

            const SizedBox(height: 8),

            // App icon + school ready
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 44,
                    height: 44,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SchoolCare',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'is ready for your school',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Success message
            Text(
              'All Set! 🎉',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your school workspace has been configured.\nOpening dashboard…',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 15,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 40),

            // Loading dots
            _LoadingDots(),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Circular Progress Arc
// ═════════════════════════════════════════════════════════════════════════════
class _CircularProgress extends StatelessWidget {
  final double value;
  const _CircularProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).toInt();
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              color: Colors.white.withValues(alpha: 0.08),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Progress
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 8,
                color: _kPurpleLight,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          // Center label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                'done',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Step Tile
// ═════════════════════════════════════════════════════════════════════════════
class _StepTile extends StatelessWidget {
  final _SetupStep step;
  final int index;
  final int total;
  const _StepTile({required this.step, required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;

    final Color dotColor;
    final Widget dotChild;
    final Color labelColor;
    final Color subColor;

    switch (step.status) {
      case _StepStatus.done:
        dotColor = _kGreen;
        dotChild = const Icon(Icons.check_rounded, color: Colors.white, size: 13);
        labelColor = Colors.white;
        subColor = Colors.white.withValues(alpha: 0.45);
        break;
      case _StepStatus.active:
        dotColor = _kPurple;
        dotChild = const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
            strokeCap: StrokeCap.round,
          ),
        );
        labelColor = Colors.white;
        subColor = _kPurpleLight.withValues(alpha: 0.85);
        break;
      case _StepStatus.error:
        dotColor = Colors.redAccent;
        dotChild = const Icon(Icons.close_rounded, color: Colors.white, size: 13);
        labelColor = Colors.white.withValues(alpha: 0.7);
        subColor = Colors.redAccent.withValues(alpha: 0.7);
        break;
      case _StepStatus.waiting:
        dotColor = Colors.transparent;
        dotChild = const SizedBox.shrink();
        labelColor = Colors.white.withValues(alpha: 0.3);
        subColor = Colors.white.withValues(alpha: 0.2);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline column
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  // Dot
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: step.status == _StepStatus.waiting
                          ? Colors.white.withValues(alpha: 0.1)
                          : dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: step.status == _StepStatus.waiting
                            ? Colors.white.withValues(alpha: 0.15)
                            : dotColor,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: step.status == _StepStatus.waiting
                          ? Text(
                              '${index + 1}',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : dotChild,
                    ),
                  ),
                  // Connector line
                  if (!isLast)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: step.status == _StepStatus.done
                              ? _kGreen.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: 20,
                  top: 10,
                  bottom: isLast ? 20 : 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.label,
                            style: GoogleFonts.outfit(
                              color: labelColor,
                              fontSize: 14,
                              fontWeight: step.status == _StepStatus.active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (step.status == _StepStatus.active)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kPurple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Running',
                              style: GoogleFonts.outfit(
                                color: _kPurpleLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (step.status == _StepStatus.done)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Done',
                              style: GoogleFonts.outfit(
                                color: _kGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.sublabel,
                      style: GoogleFonts.outfit(
                        color: subColor,
                        fontSize: 12,
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
}

// ═════════════════════════════════════════════════════════════════════════════
//  Rotating Mesh Background
// ═════════════════════════════════════════════════════════════════════════════
class _RotatingMesh extends StatelessWidget {
  final AnimationController controller;
  const _RotatingMesh({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * math.pi;
        return Stack(
          children: [
            // Top-left purple orb
            Positioned(
              top: -100 + 30 * math.sin(t * 0.7),
              left: -80 + 20 * math.cos(t * 0.5),
              child: _Orb(size: 300, color: _kPurple.withValues(alpha: 0.18)),
            ),
            // Bottom-right blue orb
            Positioned(
              bottom: -120 + 25 * math.cos(t * 0.6),
              right: -90 + 15 * math.sin(t * 0.4),
              child: _Orb(size: 280, color: _kBlue.withValues(alpha: 0.1)),
            ),
            // Mid orb
            Positioned(
              top: size.height * 0.4 + 20 * math.sin(t * 0.9),
              right: -50,
              child: _Orb(size: 180, color: _kPurpleLight.withValues(alpha: 0.08)),
            ),
            // Grid lines (subtle)
            CustomPaint(
              size: size,
              painter: _GridPainter(alpha: 0.03),
            ),
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double alpha;
  const _GridPainter({required this.alpha});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
//  Loading Dots
// ═════════════════════════════════════════════════════════════════════════════
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = ((_ctrl.value * 3 - i) % 1.0).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * math.sin(phase * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _kPurpleLight.withValues(alpha: 0.5 + 0.5 * scale),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
