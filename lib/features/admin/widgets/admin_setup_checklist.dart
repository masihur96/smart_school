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

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kPurple = Color(0xFF6C3CE1);
const _kGreen = Color(0xFF10B981);

// ═════════════════════════════════════════════════════════════════════════════
//  AdminSetupChecklist  — collapsed banner + expandable full sheet
// ═════════════════════════════════════════════════════════════════════════════
class AdminSetupChecklist extends StatefulWidget {
  const AdminSetupChecklist({super.key});

  @override
  State<AdminSetupChecklist> createState() => _AdminSetupChecklistState();
}

class _AdminSetupChecklistState extends State<AdminSetupChecklist>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandCtrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final checklist = context.watch<AdminChecklistProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!checklist.isLoaded) return const SizedBox.shrink();
    if (checklist.isDismissed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C3CE1), Color(0xFF4A1FA8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _kPurple.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Collapsed Banner ──────────────────────────────────────────
            _CollapsedBanner(
              checklist: checklist,
              expanded: _expanded,
              onToggle: _toggle,
              onDismiss: () => checklist.dismiss(),
            ),

            // ── Expandable Step List ──────────────────────────────────────
            SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: _expandCtrl,
                curve: Curves.easeInOutCubic,
              ),
              child: _StepList(checklist: checklist, isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Collapsed Banner ─────────────────────────────────────────────────────────
class _CollapsedBanner extends StatelessWidget {
  final AdminChecklistProvider checklist;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDismiss;

  const _CollapsedBanner({
    required this.checklist,
    required this.expanded,
    required this.onToggle,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final done = checklist.completedCount;
    final total = checklist.totalCount;
    final pct = checklist.progress;

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            // Circular mini progress
            SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 4,
                    color: Colors.white.withValues(alpha: 0.15),
                    strokeCap: StrokeCap.round,
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 4,
                      color: _kGreen,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$done/$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Up Your School',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    done == total
                        ? '🎉 All steps complete! Tap to review.'
                        : '${total - done} step${total - done > 1 ? 's' : ''} remaining — tap to continue',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron / dismiss
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step List ────────────────────────────────────────────────────────────────
class _StepList extends StatelessWidget {
  final AdminChecklistProvider checklist;
  final bool isDark;

  const _StepList({required this.checklist, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1035).withValues(alpha: 0.95)
            : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.checklist_rounded,
                  color: _kPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Getting Started Guide',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1035),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${checklist.completedCount}/${checklist.totalCount} done',
                  style: TextStyle(
                    color: _kGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: checklist.progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor:
                      isDark ? Colors.white12 : const Color(0xFFE9E5F8),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_kGreen),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Steps
          ...checklist.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return _StepTile(
              step: step,
              stepNumber: index + 1,
              isDark: isDark,
              onTap: () => _navigateToStep(context, step),
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _navigateToStep(BuildContext context, ChecklistStep step) {
    final checklist = context.read<AdminChecklistProvider>();

    switch (step.id) {
      case ChecklistStepId.addTeacher:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTeacherScreen()),
        ).then((_) {
          // Mark as visited — actual completion happens when teacher is saved
        });
        break;
      case ChecklistStepId.addStudent:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
        );
        break;
      case ChecklistStepId.addClass:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        ).then((_) => checklist.onClassReviewed());
        break;
      case ChecklistStepId.addExam:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamManagementScreen()),
        ).then((_) {
          // Exam completion handled by exam provider hook
        });
        break;
      case ChecklistStepId.addNotice:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoticeManagementScreen()),
        );
        break;
      case ChecklistStepId.setupRoutine:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoutineManagementScreen()),
        ).then((_) => checklist.onRoutineSetup());
        break;
      case ChecklistStepId.exploreAttendance:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentAttendanceManagementScreen(),
          ),
        ).then((_) => checklist.onAttendanceExplored());
        break;
    }
  }
}

// ─── Individual Step Tile ─────────────────────────────────────────────────────
class _StepTile extends StatelessWidget {
  final ChecklistStep step;
  final int stepNumber;
  final bool isDark;
  final VoidCallback onTap;

  const _StepTile({
    required this.step,
    required this.stepNumber,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = step.isCompleted;
    final textColor =
        isDark ? Colors.white : const Color(0xFF1A1035);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF6B7280);

    return AnimatedOpacity(
      opacity: completed ? 0.65 : 1.0,
      duration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: completed ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Step icon / check
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: completed
                      ? _kGreen.withValues(alpha: 0.12)
                      : step.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: completed
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: _kGreen,
                        size: 24,
                      )
                    : Icon(
                        step.icon,
                        color: step.color,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.description,
                      style: TextStyle(
                        color: subColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow or done badge
              if (!completed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: step.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: step.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Go',
                        style: TextStyle(
                          color: step.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: step.color,
                        size: 12,
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Done ✓',
                  style: TextStyle(
                    color: _kGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
