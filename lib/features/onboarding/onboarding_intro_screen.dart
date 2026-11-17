import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/features/auth/presntation/views/login_screen.dart';

// ─── Slide Data Model ────────────────────────────────────────────────────────
class _OnboardingSlide {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<_Feature> features;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.features,
  });
}

class _Feature {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
}

// ─── Slide Definitions ──────────────────────────────────────────────────────
const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    title: 'SchoolCare',
    subtitle: 'Smart School Management',
    description:
        'Transform the way your institution operates. Everything you need — in one powerful platform built for the modern classroom.',
    icon: Icons.school_rounded,
    gradient: [Color(0xFF6C3CE1), Color(0xFF9B6DFF)],
    features: [
      _Feature(Icons.admin_panel_settings_rounded, 'Admin Control'),
      _Feature(Icons.groups_rounded, 'Multi-Role Access'),
      _Feature(Icons.cloud_done_rounded, 'Cloud Synced'),
    ],
  ),
  _OnboardingSlide(
    title: 'Stay Connected',
    subtitle: 'Parents · Teachers · Students',
    description:
        'Real-time attendance, homework updates, exam results and notices — delivered instantly to everyone in your school community.',
    icon: Icons.connect_without_contact_rounded,
    gradient: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    features: [
      _Feature(Icons.notifications_active_rounded, 'Live Alerts'),
      _Feature(Icons.chat_bubble_rounded, 'Notice Board'),
      _Feature(Icons.how_to_reg_rounded, 'Attendance'),
    ],
  ),
  _OnboardingSlide(
    title: 'Exam & Results',
    subtitle: 'Academic Excellence Tracker',
    description:
        'Schedule exams, record marks, generate report cards and admit cards. Full academic lifecycle management at your fingertips.',
    icon: Icons.bar_chart_rounded,
    gradient: [Color(0xFF10B981), Color(0xFF34D399)],
    features: [
      _Feature(Icons.assignment_rounded, 'Exam Schedule'),
      _Feature(Icons.grading_rounded, 'Mark Entry'),
      _Feature(Icons.picture_as_pdf_rounded, 'PDF Reports'),
    ],
  ),
  _OnboardingSlide(
    title: 'Ready to Begin?',
    subtitle: 'Your school journey starts here',
    description:
        'Set up your school in minutes. Register, configure classes and subjects — and go live with your team today.',
    icon: Icons.rocket_launch_rounded,
    gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    features: [
      _Feature(Icons.bolt_rounded, 'Quick Setup'),
      _Feature(Icons.verified_rounded, 'Secure & Reliable'),
      _Feature(Icons.support_agent_rounded, '24/7 Support'),
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
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _bgController;
  late final AnimationController _contentController;

  int _currentPage = 0;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Lock to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _contentController.reset();
    _contentController.forward();
    setState(() {
      _currentPage = index;
      _isLastPage = index == _slides.length - 1;
    });
  }

  Future<void> _completeOnboarding() async {
    await StorageService.saveHasSeenOnboarding(true);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  void _next() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: slide.gradient,
            ),
          ),
          child: Stack(
            children: [
              // ── Animated background orbs ──
              _AnimatedOrbs(
                controller: _bgController,
                colors: slide.gradient,
                size: size,
              ),

              // ── Page content ──
              SafeArea(
                child: Column(
                  children: [
                    // Skip button
                    _buildTopBar(),

                    // Page view
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _slides.length,
                        itemBuilder: (_, i) => _SlidePage(
                          slide: _slides[i],
                          contentController: _contentController,
                          isActive: i == _currentPage,
                        ),
                      ),
                    ),

                    // Bottom nav
                    _buildBottomNav(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page indicator dots
          Row(
            children: List.generate(
              _slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 6),
                width: i == _currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          // Skip button
          if (!_isLastPage)
            GestureDetector(
              onTap: _completeOnboarding,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Skip',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 36),
      child: Row(
        children: [
          // Back button
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _currentPage > 0 ? 1 : 0,
            child: GestureDetector(
              onTap: _currentPage > 0
                  ? () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      )
                  : null,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Next / Get Started button
          GestureDetector(
            onTap: _next,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: _isLastPage ? 32 : 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isLastPage
                        ? Text(
                            'Get Started',
                            key: const ValueKey('start'),
                            style: GoogleFonts.outfit(
                              color: _slides[_currentPage].gradient.first,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                  if (_isLastPage) const SizedBox(width: 10),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _slides[_currentPage].gradient.first,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
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
}

// ═════════════════════════════════════════════════════════════════════════════
//  Single Slide Page
// ═════════════════════════════════════════════════════════════════════════════
class _SlidePage extends StatelessWidget {
  final _OnboardingSlide slide;
  final AnimationController contentController;
  final bool isActive;

  const _SlidePage({
    required this.slide,
    required this.contentController,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final fadeAnim = CurvedAnimation(
      parent: contentController,
      curve: Curves.easeOut,
    );
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: contentController,
      curve: Curves.easeOutCubic,
    ));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Hero Icon ──
              _HeroIconWidget(slide: slide),

              const SizedBox(height: 48),

              // ── Title ──
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              // ── Subtitle badge ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  slide.subtitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Description ──
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 36),

              // ── Feature chips ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: slide.features
                    .map((f) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _FeatureChip(feature: f),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Icon with floating ring animation ───────────────────────────────
class _HeroIconWidget extends StatefulWidget {
  final _OnboardingSlide slide;
  const _HeroIconWidget({required this.slide});

  @override
  State<_HeroIconWidget> createState() => _HeroIconWidgetState();
}

class _HeroIconWidgetState extends State<_HeroIconWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
          ),
          // Middle ring
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
          ),
          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              widget.slide.icon,
              size: 56,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature Chip ─────────────────────────────────────────────────────────
class _FeatureChip extends StatelessWidget {
  final _Feature feature;
  const _FeatureChip({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feature.icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            feature.label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Orbs Background ─────────────────────────────────────────────
class _AnimatedOrbs extends StatelessWidget {
  final AnimationController controller;
  final List<Color> colors;
  final Size size;

  const _AnimatedOrbs({
    required this.controller,
    required this.colors,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(
          children: [
            // Top-right orb
            Positioned(
              top: -60 + 20 * math.sin(t * math.pi),
              right: -80 + 15 * math.cos(t * math.pi),
              child: _Orb(size: 220, color: Colors.white.withValues(alpha: 0.06)),
            ),
            // Bottom-left orb
            Positioned(
              bottom: -80 + 20 * math.cos(t * math.pi),
              left: -60 + 15 * math.sin(t * math.pi),
              child: _Orb(size: 260, color: Colors.white.withValues(alpha: 0.05)),
            ),
            // Mid-right accent
            Positioned(
              top: size.height * 0.35 + 15 * math.sin(t * math.pi * 1.5),
              right: -40,
              child: _Orb(size: 140, color: Colors.white.withValues(alpha: 0.07)),
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
        color: color,
      ),
    );
  }
}
