import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/admin_checklist_provider.dart';
import 'package:smart_school/features/admin/screens/add_edit_student_screen.dart';
import 'package:smart_school/features/admin/screens/add_edit_teacher_screen.dart';
import 'package:smart_school/features/admin/screens/exam_management_screen.dart';
import 'package:smart_school/features/admin/screens/notice_management_screen.dart';
import 'package:smart_school/features/admin/screens/routine_management_screen.dart';
import 'package:smart_school/features/admin/screens/setup_screen.dart';
import 'package:smart_school/features/admin/screens/student_attendance_management_screen.dart';
import 'package:smart_school/features/admin/screens/student_management_screen.dart';
import 'package:smart_school/features/admin/screens/teacher_management_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';

// ─── Color palette ────────────────────────────────────────────────────────────
const _kViolet = Color(0xFF6C3CE1);
const _kVioletDark = Color(0xFF4A1FA8);
const _kVioletLight = Color(0xFF9B6DFF);
const _kGreen = Color(0xFF10B981);
const _kAmber = Color(0xFFF59E0B);
const _kBlue = Color(0xFF0EA5E9);
const _kRed = Color(0xFFEF4444);

// ═════════════════════════════════════════════════════════════════════════════
//  SchoolSetupGuide
//  Replaces normal dashboard content when no teacher OR no student exists.
// ═════════════════════════════════════════════════════════════════════════════
class SchoolSetupGuide extends StatefulWidget {
  final bool hasTeachers;
  final bool hasStudents;
  final VoidCallback onRefresh;

  const SchoolSetupGuide({
    super.key,
    required this.hasTeachers,
    required this.hasStudents,
    required this.onRefresh,
  });

  @override
  State<SchoolSetupGuide> createState() => _SchoolSetupGuideState();
}

class _SchoolSetupGuideState extends State<SchoolSetupGuide>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checklist = context.watch<AdminChecklistProvider>();
    final auth = context.watch<AuthNotifier>();
    final schoolName = auth.user?.school?.name ?? 'Your School';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine missing items
    final missingTeacher = !widget.hasTeachers;
    final missingStudent = !widget.hasStudents;

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeCtrl,
          child: Column(
            children: [
              // ── Hero Header ──────────────────────────────────────────────
              _HeroHeader(
                bgCtrl: _bgCtrl,
                pulseCtrl: _pulseCtrl,
                schoolName: schoolName,
                missingTeacher: missingTeacher,
                missingStudent: missingStudent,
              ),

              // ── Alert Banner ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _AlertBanner(
                  missingTeacher: missingTeacher,
                  missingStudent: missingStudent,
                ),
              ),

              const SizedBox(height: 20),

              // ── Step Cards ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StepGuide(
                  checklist: checklist,
                  missingTeacher: missingTeacher,
                  missingStudent: missingStudent,
                  isDark: isDark,
                ),
              ),

              const SizedBox(height: 20),

              // ── Progress Footer ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: _ProgressFooter(
                  checklist: checklist,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Hero Header
// ═════════════════════════════════════════════════════════════════════════════
class _HeroHeader extends StatelessWidget {
  final AnimationController bgCtrl;
  final AnimationController pulseCtrl;
  final String schoolName;
  final bool missingTeacher;
  final bool missingStudent;

  const _HeroHeader({
    required this.bgCtrl,
    required this.pulseCtrl,
    required this.schoolName,
    required this.missingTeacher,
    required this.missingStudent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Animated gradient background ──
        AnimatedBuilder(
          animation: bgCtrl,
          builder: (_, __) => CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 260),
            painter: _WavePainter(bgCtrl.value),
          ),
        ),

        // ── Content ──
        SizedBox(
          height: 260,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // Pulsing school icon
                AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (_, child) => Transform.scale(
                    scale: 1.0 + pulseCtrl.value * 0.06,
                    child: child,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Welcome to $schoolName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    missingTeacher && missingStudent
                        ? 'Your school is set up! Now add teachers & students to unlock all features.'
                        : missingTeacher
                            ? 'Great start! Add at least one teacher to manage classes and attendance.'
                            : 'Almost there! Enroll your first student to complete setup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Status chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatusChip(
                      icon: Icons.person_rounded,
                      label: 'Teacher',
                      done: !missingTeacher,
                    ),
                    const SizedBox(width: 10),
                    _StatusChip(
                      icon: Icons.school_rounded,
                      label: 'Student',
                      done: !missingStudent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? _kGreen.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done
              ? _kGreen.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: done ? _kGreen : Colors.white70,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: done ? _kGreen : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Alert Banner
// ═════════════════════════════════════════════════════════════════════════════
class _AlertBanner extends StatelessWidget {
  final bool missingTeacher;
  final bool missingStudent;

  const _AlertBanner({
    required this.missingTeacher,
    required this.missingStudent,
  });

  @override
  Widget build(BuildContext context) {
    final both = missingTeacher && missingStudent;
    final color = both ? _kAmber : _kBlue;
    final icon = both ? Icons.warning_amber_rounded : Icons.info_rounded;
    final message = both
        ? 'No teachers or students found. Follow the steps below to get started.'
        : missingTeacher
            ? 'No teachers added yet. Add a teacher to enable attendance, homework & more.'
            : 'No students enrolled yet. Enroll students to track their progress.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Step Guide — ordered action cards
// ═════════════════════════════════════════════════════════════════════════════
class _StepGuide extends StatelessWidget {
  final AdminChecklistProvider checklist;
  final bool missingTeacher;
  final bool missingStudent;
  final bool isDark;

  const _StepGuide({
    required this.checklist,
    required this.missingTeacher,
    required this.missingStudent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Build ordered steps based on what's missing
    final steps = <_GuideStep>[
      _GuideStep(
        step: 1,
        icon: Icons.class_rounded,
        color: _kViolet,
        title: 'Review Classes & Sections',
        subtitle: 'Auto-setup created Class 1–5 with Section A. Customize as needed.',
        status: checklist.steps
            .firstWhere((s) => s.id == ChecklistStepId.addClass)
            .isCompleted
            ? _StepState.done
            : _StepState.suggested,
        action: 'Open Setup',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        ).then((_) => checklist.onClassReviewed()),
        isRequired: false,
      ),
      _GuideStep(
        step: 2,
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF8B5CF6),
        title: 'Add Your First Teacher',
        subtitle: 'Teachers can mark attendance, assign homework, and enter marks.',
        status: !missingTeacher
            ? _StepState.done
            : checklist.steps
                    .firstWhere((s) => s.id == ChecklistStepId.addClass)
                    .isCompleted
                ? _StepState.suggested
                : _StepState.locked,
        action: !missingTeacher ? 'View Teachers' : 'Add Teacher',
        onTap: () {
          if (!missingTeacher) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TeacherManagementScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddEditTeacherScreen()),
            );
          }
        },
        isRequired: true,
      ),
      _GuideStep(
        step: 3,
        icon: Icons.school_rounded,
        color: _kBlue,
        title: 'Enroll Your First Student',
        subtitle: 'Assign students to classes. They can then log in to view results, homework & notices.',
        status: !missingStudent
            ? _StepState.done
            : !missingTeacher
                ? _StepState.suggested
                : _StepState.locked,
        action: !missingStudent ? 'View Students' : 'Enroll Student',
        onTap: () {
          if (!missingStudent) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StudentManagementScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddEditStudentScreen()),
            );
          }
        },
        isRequired: true,
      ),
      _GuideStep(
        step: 4,
        icon: Icons.assignment_turned_in_rounded,
        color: _kRed,
        title: 'Create Your First Exam',
        subtitle: 'Set up an exam schedule. Teachers can then enter marks for students.',
        status: checklist.steps
            .firstWhere((s) => s.id == ChecklistStepId.addExam)
            .isCompleted
            ? _StepState.done
            : (missingTeacher || missingStudent)
                ? _StepState.locked
                : _StepState.suggested,
        action: 'Create Exam',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamManagementScreen()),
        ),
        isRequired: false,
      ),
      _GuideStep(
        step: 5,
        icon: Icons.announcement_rounded,
        color: _kAmber,
        title: 'Post Your First Notice',
        subtitle: 'Broadcast announcements to all teachers and students instantly.',
        status: checklist.steps
            .firstWhere((s) => s.id == ChecklistStepId.addNotice)
            .isCompleted
            ? _StepState.done
            : (missingTeacher || missingStudent)
                ? _StepState.locked
                : _StepState.suggested,
        action: 'Post Notice',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoticeManagementScreen()),
        ),
        isRequired: false,
      ),
      _GuideStep(
        step: 6,
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF059669),
        title: 'Set Up Class Routine',
        subtitle: 'Create a weekly timetable so teachers and students know their schedule.',
        status: checklist.steps
            .firstWhere((s) => s.id == ChecklistStepId.setupRoutine)
            .isCompleted
            ? _StepState.done
            : (missingTeacher || missingStudent)
                ? _StepState.locked
                : _StepState.suggested,
        action: 'Create Routine',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoutineManagementScreen()),
        ).then((_) => checklist.onRoutineSetup()),
        isRequired: false,
      ),
      _GuideStep(
        step: 7,
        icon: Icons.how_to_reg_rounded,
        color: _kGreen,
        title: 'Explore Attendance Tracking',
        subtitle: 'Monitor daily teacher & student attendance from one place.',
        status: checklist.steps
            .firstWhere(
                (s) => s.id == ChecklistStepId.exploreAttendance)
            .isCompleted
            ? _StepState.done
            : (missingTeacher || missingStudent)
                ? _StepState.locked
                : _StepState.suggested,
        action: 'View Attendance',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const StudentAttendanceManagementScreen()),
        ).then(
            (_) => checklist.onAttendanceExplored()),
        isRequired: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: _kViolet,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Setup Steps',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _kViolet.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Follow in order',
                style: TextStyle(
                  color: _kViolet,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Step cards
        ...steps.asMap().entries.map((e) {
          final isLast = e.key == steps.length - 1;
          return _StepCard(
            step: e.value,
            isDark: isDark,
            isLast: isLast,
          );
        }),
      ],
    );
  }
}

enum _StepState { done, suggested, locked }

class _GuideStep {
  final int step;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final _StepState status;
  final String action;
  final VoidCallback onTap;
  final bool isRequired;

  const _GuideStep({
    required this.step,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.action,
    required this.onTap,
    required this.isRequired,
  });
}

class _StepCard extends StatelessWidget {
  final _GuideStep step;
  final bool isDark;
  final bool isLast;

  const _StepCard({
    required this.step,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = step.status == _StepState.done;
    final isLocked = step.status == _StepState.locked;
    final isSuggested = step.status == _StepState.suggested;

    final cardBg = isDark
        ? (isDone
            ? const Color(0xFF162820)
            : isLocked
                ? const Color(0xFF1A1A2E)
                : const Color(0xFF1E1A32))
        : (isDone
            ? const Color(0xFFF0FDF4)
            : isLocked
                ? const Color(0xFFF8F8FC)
                : Colors.white);

    final borderColor = isDone
        ? _kGreen.withValues(alpha: 0.4)
        : isSuggested
            ? step.color.withValues(alpha: 0.5)
            : (isDark ? Colors.white10 : const Color(0xFFE5E7EB));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline column ──────────────────────────────────────────
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Step dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? _kGreen
                        : isSuggested
                            ? step.color
                            : (isDark
                                ? Colors.white12
                                : const Color(0xFFE9E9F0)),
                    boxShadow: isSuggested
                        ? [
                            BoxShadow(
                              color: step.color.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : isLocked
                            ? Icon(
                                Icons.lock_rounded,
                                color: isDark
                                    ? Colors.white30
                                    : Colors.grey.shade400,
                                size: 15,
                              )
                            : Text(
                                '${step.step}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                  ),
                ),

                // Connector line
                if (!isLast)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: isDone
                            ? _kGreen.withValues(alpha: 0.4)
                            : (isDark
                                ? Colors.white10
                                : const Color(0xFFE0E0EE)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Card body ────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: isSuggested ? 1.5 : 1,
                  ),
                  boxShadow: isSuggested
                      ? [
                          BoxShadow(
                            color: step.color.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icon badge
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isDone ? _kGreen : step.color)
                                  .withValues(alpha: isDone ? 0.12 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : step.icon,
                              color: isDone ? _kGreen : step.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        step.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDone
                                              ? _kGreen
                                              : isLocked
                                                  ? (isDark
                                                      ? Colors.white38
                                                      : Colors.grey.shade400)
                                                  : (isDark
                                                      ? Colors.white
                                                      : const Color(0xFF1A1035)),
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (step.isRequired && !isDone)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              _kRed.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _kRed.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: const Text(
                                          'Required',
                                          style: TextStyle(
                                            color: _kRed,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        step.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? Colors.white.withValues(
                                  alpha: isLocked ? 0.3 : 0.6)
                              : (isLocked
                                  ? Colors.grey.shade400
                                  : const Color(0xFF6B7280)),
                          height: 1.4,
                        ),
                      ),

                      if (!isLocked) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: ElevatedButton.icon(
                              onPressed: isDone ? null : step.onTap,
                              icon: Icon(
                                isDone
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                              label: Text(
                                isDone ? 'Completed ✓' : step.action,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDone ? _kGreen : step.color,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    _kGreen.withValues(alpha: 0.6),
                                disabledForegroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: isDone ? 0 : 2,
                                shadowColor:
                                    step.color.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade400,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Complete previous steps first',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Progress Footer
// ═════════════════════════════════════════════════════════════════════════════
class _ProgressFooter extends StatelessWidget {
  final AdminChecklistProvider checklist;
  final bool isDark;

  const _ProgressFooter({required this.checklist, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final done = checklist.completedCount;
    final total = checklist.totalCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kViolet.withValues(alpha: isDark ? 0.25 : 0.08),
            _kVioletLight.withValues(alpha: isDark ? 0.15 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _kViolet.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_rounded,
                  color: _kViolet, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Overall Setup Progress',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1035),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$done / $total steps',
                style: const TextStyle(
                  color: _kViolet,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: checklist.progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor:
                    isDark ? Colors.white12 : const Color(0xFFE9E5F8),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(_kViolet),
              ),
            ),
          ),
          if (done == total) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration_rounded,
                    color: _kGreen, size: 16),
                const SizedBox(width: 6),
                Text(
                  'All set! Your school is ready to go. 🎉',
                  style: const TextStyle(
                    color: _kGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Wave Background Painter
// ═════════════════════════════════════════════════════════════════════════════
class _WavePainter extends CustomPainter {
  final double t;
  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient fill
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_kVioletDark, _kViolet, const Color(0xFF7C4DFF)],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = gradient);

    // Animated wave overlay
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.6);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.6 +
          math.sin((x / size.width * 2 * math.pi) + t * 2 * math.pi) * 25;
      path1.lineTo(x, y);
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, wavePaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.75 +
          math.sin((x / size.width * 2 * math.pi) + t * 2 * math.pi + 1) *
              20;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, Paint()..color = Colors.black.withValues(alpha: 0.1));
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}
