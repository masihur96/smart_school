import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/features/auth/presntation/views/login_screen.dart';

// ─── Color Tokens ─────────────────────────────────────────────────────────────
class _OnboardingTheme {
  static const Color purplePrimary   = Color(0xFF6C3CE1);
  static const Color purpleGradient  = Color(0xFF8B5CF6);
  static const Color blueAccent      = Color(0xFF0284C7);
  static const Color emeraldAccent   = Color(0xFF059669);
  static const Color amberAccent     = Color(0xFFD97706);

  static const Color textDark        = Color(0xFF0F172A);
  static const Color textMuted       = Color(0xFF64748B);
  static const Color cardBorder      = Color(0xFFE2E8F0);
}

// ─── Slide Data Model ─────────────────────────────────────────────────────────
class _OnboardingData {
  final String category;
  final String title;
  final String highlightWord;
  final String description;
  final Color primaryColor;
  final Color bgTint;
  final List<String> bulletPoints;

  const _OnboardingData({
    required this.category,
    required this.title,
    required this.highlightWord,
    required this.description,
    required this.primaryColor,
    required this.bgTint,
    required this.bulletPoints,
  });
}

const List<_OnboardingData> _onboardingSlides = [
  _OnboardingData(
    category: 'ALL-IN-ONE PLATFORM',
    title: 'Smart Digital Campus for Your School',
    highlightWord: 'Digital Campus',
    description:
        'Unified management ecosystem empowering Principals, Teachers, Students, and Parents under one intuitive mobile application.',
    primaryColor: _OnboardingTheme.purplePrimary,
    bgTint: Color(0xFFF5F3FF),
    bulletPoints: [
      'Multi-Role Dashboards (Admin, Teacher, Student)',
      'Real-Time Notice Board & Institutional Marquee',
      'Centralized Student & Staff Profiles',
    ],
  ),
  _OnboardingData(
    category: 'SMART ATTENDANCE & SMS',
    title: 'Daily Attendance & Instant Alerts',
    highlightWord: 'Attendance & Alerts',
    description:
        'Mark subject & period attendance in seconds. Keep guardians instantly notified via automated SMS and live push notifications.',
    primaryColor: _OnboardingTheme.blueAccent,
    bgTint: Color(0xFFF0F9FF),
    bulletPoints: [
      'One-Tap Attendance with Biometric Option',
      'Automated SMS Notifications to Parents',
      'Monthly Attendance Statistics & Defaulter List',
    ],
  ),
  _OnboardingData(
    category: 'ACADEMICS & RESULTS',
    title: 'Exams, Marksheets & PDF Reports',
    highlightWord: 'PDF Reports',
    description:
        'Manage exam schedules, grade entries, and produce print-ready PDF Admit Cards, ID Cards, and student Transcripts instantly.',
    primaryColor: _OnboardingTheme.emeraldAccent,
    bgTint: Color(0xFFF0FDF4),
    bulletPoints: [
      'Digital Marks Entry with Auto GPA Calculation',
      'Generate Admit Cards, ID Cards & Report Cards',
      'Class Routine & Timetable Management',
    ],
  ),
  _OnboardingData(
    category: 'FAST ONBOARDING',
    title: 'Launch Your School in 2 Minutes',
    highlightWord: '2 Minutes',
    description:
        'Register your school and let our automated system pre-configure your classes, sections, and subjects so you can start right away.',
    primaryColor: _OnboardingTheme.amberAccent,
    bgTint: Color(0xFFFFFBEB),
    bulletPoints: [
      'Auto-Setup Classes 1 to 5 with Default Subjects',
      'Complimentary Free Tier to Get Started',
      'Secure Cloud Data with 24/7 Availability',
    ],
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
//  OnboardingIntroScreen
// ═════════════════════════════════════════════════════════════════════════════
class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({super.key});

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    await StorageService.saveHasSeenOnboarding(true);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _onboardingSlides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _onboardingSlides[_currentPage];
    final isLastPage = _currentPage == _onboardingSlides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                currentSlide.bgTint,
                Colors.white,
              ],
              stops: const [0.0, 0.55],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Top Navigation Bar ──
                _buildTopBar(isLastPage),

                // ── Main Slide Carousel ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _onboardingSlides.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _animController.reset();
                      _animController.forward();
                    },
                    itemBuilder: (context, index) {
                      return _SlideItem(
                        data: _onboardingSlides[index],
                        pageIndex: index,
                        animController: _animController,
                      );
                    },
                  ),
                ),

                // ── Bottom Action Panel ──
                _buildBottomControls(currentSlide, isLastPage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _OnboardingTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SchoolCare',
                  style: GoogleFonts.outfit(
                    color: _OnboardingTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Skip button
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isLastPage ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: isLastPage,
              child: TextButton(
                onPressed: _finishOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: _OnboardingTheme.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skip',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _OnboardingTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: _OnboardingTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Controls ───────────────────────────────────────────────────────
  Widget _buildBottomControls(_OnboardingData currentSlide, bool isLastPage) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingSlides.length,
              (index) {
                final isSelected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? currentSlide.primaryColor
                        : _OnboardingTheme.cardBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons row
          Row(
            children: [
              // Back Button
              if (_currentPage > 0) ...[
                InkWell(
                  onTap: _previousPage,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _OnboardingTheme.cardBorder),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: _OnboardingTheme.textDark,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Next / Get Started button
              Expanded(
                child: GestureDetector(
                  onTap: _nextPage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLastPage
                            ? [
                                _OnboardingTheme.purplePrimary,
                                _OnboardingTheme.purpleGradient,
                              ]
                            : [
                                currentSlide.primaryColor,
                                currentSlide.primaryColor.withValues(alpha: 0.85),
                              ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: currentSlide.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? 'Get Started Now' : 'Continue',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),
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
//  Single Slide View
// ═════════════════════════════════════════════════════════════════════════════
class _SlideItem extends StatelessWidget {
  final _OnboardingData data;
  final int pageIndex;
  final AnimationController animController;

  const _SlideItem({
    required this.data,
    required this.pageIndex,
    required this.animController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Top Illustration Graphic (50% of available height)
                    Expanded(
                      flex: 11,
                      child: Center(
                        child: _SlideVisualWidget(
                          pageIndex: pageIndex,
                          primaryColor: data.primaryColor,
                        ),
                      ),
                    ),

                    // Bottom Content Text & Bullet Points
                    Expanded(
                      flex: 12,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animController,
                          curve: Curves.easeOut,
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Category Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: data.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data.category,
                                  style: GoogleFonts.outfit(
                                    color: data.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Title
                              Text(
                                data.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: _OnboardingTheme.textDark,
                                  height: 1.2,
                                  letterSpacing: -0.4,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Description
                              Text(
                                data.description,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  color: _OnboardingTheme.textMuted,
                                  height: 1.45,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Feature Highlights Bullet Rows
                              ...data.bulletPoints.map(
                                (point) => Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: data.primaryColor.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 12,
                                          color: data.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: _OnboardingTheme.textDark,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Visual Graphic per Slide (Using project assets)
// ═════════════════════════════════════════════════════════════════════════════
class _SlideVisualWidget extends StatelessWidget {
  final int pageIndex;
  final Color primaryColor;

  const _SlideVisualWidget({
    required this.pageIndex,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (pageIndex) {
      case 0:
        return _buildSlide1LogoVisual();
      case 1:
        return _buildSlide2TutorVisual();
      case 2:
        return _buildSlide3AcademicVisual();
      case 3:
        return _buildSlide4LottieVisual();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Slide 1: App Icon Hero with Floating Feature Badges ───────────────────
  Widget _buildSlide1LogoVisual() {
    return SizedBox(
      height: 220,
      width: 290,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background soft glowing aura
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _OnboardingTheme.purplePrimary.withValues(alpha: 0.08),
            ),
          ),
          // Subtle decorative ring
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _OnboardingTheme.purplePrimary.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
          ),

          // Central App Icon inside card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: _OnboardingTheme.purplePrimary.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: _OnboardingTheme.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/icon/icon.png',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Floating Chip Top-Right: Admin Portal
          Positioned(
            top: 10,
            right: 0,
            child: _FloatingChip(
              icon: Icons.admin_panel_settings_rounded,
              label: 'Admin Portal',
              color: _OnboardingTheme.purplePrimary,
            ),
          ),

          // Floating Chip Bottom-Left: Teacher & Student
          Positioned(
            bottom: 12,
            left: 0,
            child: _FloatingChip(
              icon: Icons.school_rounded,
              label: 'Teacher & Student',
              color: _OnboardingTheme.blueAccent,
            ),
          ),

          // Floating Mini Badge: Cloud Synced
          Positioned(
            top: 24,
            left: 8,
            child: _FloatingMiniBadge(
              icon: Icons.cloud_done_rounded,
              color: _OnboardingTheme.emeraldAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide 2: Tutor Asset with Attendance & Parent SMS Overlays ────────────
  Widget _buildSlide2TutorVisual() {
    return SizedBox(
      height: 230,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background soft pill
          Container(
            width: 220,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(32),
            ),
          ),

          // Tutor Illustration Asset
          Positioned(
            bottom: 4,
            child: Image.asset(
              'assets/tutor.png',
              height: 185,
              fit: BoxFit.contain,
            ),
          ),

          // Floating Chip Top-Right: Attendance Live
          Positioned(
            top: 14,
            right: 4,
            child: _FloatingChip(
              icon: Icons.check_circle_rounded,
              label: '98.5% Present',
              color: _OnboardingTheme.emeraldAccent,
            ),
          ),

          // Floating Chip Bottom-Left: SMS to Parents
          Positioned(
            bottom: 12,
            left: 2,
            child: _FloatingChip(
              icon: Icons.sms_rounded,
              label: 'Parent SMS Alerts',
              color: _OnboardingTheme.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide 3: Interactive Academic Dashboard Card ──────────────────────────
  Widget _buildSlide3AcademicVisual() {
    return Container(
      width: 275,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _OnboardingTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: _OnboardingTheme.emeraldAccent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _OnboardingTheme.emeraldAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: _OnboardingTheme.emeraldAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Term 1 Report Card',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _OnboardingTheme.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _OnboardingTheme.emeraldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'GPA 5.00',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _OnboardingTheme.emeraldAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Subject Bars
          _buildMiniBar('Mathematics', 0.95, _OnboardingTheme.purplePrimary),
          const SizedBox(height: 6),
          _buildMiniBar('General Science', 0.90, _OnboardingTheme.emeraldAccent),
          const SizedBox(height: 6),
          _buildMiniBar('English Language', 0.88, _OnboardingTheme.blueAccent),

          const SizedBox(height: 12),

          // Action Chips Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _OnboardingTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          size: 13, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Admit Card',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _OnboardingTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _OnboardingTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.badge_rounded,
                          size: 13, color: _OnboardingTheme.blueAccent),
                      const SizedBox(width: 4),
                      Text(
                        'ID Cards',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _OnboardingTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: _OnboardingTheme.textMuted,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 5,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── Slide 4: Lottie Bot Interactive Animation ─────────────────────────────
  Widget _buildSlide4LottieVisual() {
    return SizedBox(
      height: 220,
      width: 290,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background soft pill
          Container(
            width: 200,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(36),
            ),
          ),

          // Lottie Bot Asset
          SizedBox(
            height: 190,
            width: 190,
            child: Lottie.asset(
              'assets/animation1.json',
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),

          // Floating Chip Top-Right: 2-Min Setup
          Positioned(
            top: 10,
            right: 2,
            child: _FloatingChip(
              icon: Icons.bolt_rounded,
              label: '2-Minute Setup',
              color: _OnboardingTheme.amberAccent,
            ),
          ),

          // Floating Chip Bottom-Left: Auto Class Setup
          Positioned(
            bottom: 8,
            left: 2,
            child: _FloatingChip(
              icon: Icons.auto_awesome_rounded,
              label: 'Classes Pre-configured',
              color: _OnboardingTheme.purplePrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Floating Badges & Micro Widgets
// ═════════════════════════════════════════════════════════════════════════════
class _FloatingChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FloatingChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingMiniBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FloatingMiniBadge({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
