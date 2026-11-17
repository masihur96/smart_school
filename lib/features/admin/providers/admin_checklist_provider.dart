import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Checklist Step Model ─────────────────────────────────────────────────────

enum ChecklistStepId {
  addTeacher,
  addStudent,
  addClass,
  addExam,
  addNotice,
  setupRoutine,
  exploreAttendance,
}

class ChecklistStep {
  final ChecklistStepId id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  bool isCompleted;

  ChecklistStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
    this.isCompleted = false,
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────────

class AdminChecklistProvider extends ChangeNotifier {
  static const String _prefKeyPrefix = 'checklist_step_';
  static const String _checklistDismissedKey = 'checklist_dismissed';
  static const String _checklistCompletedKey = 'checklist_all_completed';

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool _isDismissed = false;
  bool get isDismissed => _isDismissed;

  bool _isAllCompleted = false;
  bool get isAllCompleted => _isAllCompleted;

  late final List<ChecklistStep> steps;

  AdminChecklistProvider() {
    _initSteps();
    _loadFromPrefs();
  }

  void _initSteps() {
    steps = [
      ChecklistStep(
        id: ChecklistStepId.addTeacher,
        title: 'Add Your First Teacher',
        description: 'Onboard a teacher to manage classes & attendance.',
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF6C3CE1),
        route: '/admin/teachers/add',
      ),
      ChecklistStep(
        id: ChecklistStepId.addStudent,
        title: 'Enroll Your First Student',
        description: 'Register a student and assign them to a class.',
        icon: Icons.school_rounded,
        color: const Color(0xFF0EA5E9),
        route: '/admin/students/add',
      ),
      ChecklistStep(
        id: ChecklistStepId.addClass,
        title: 'Review Classes & Sections',
        description: 'Verify or customize the auto-created classes.',
        icon: Icons.class_rounded,
        color: const Color(0xFF10B981),
        route: '/admin/setup',
      ),
      ChecklistStep(
        id: ChecklistStepId.addExam,
        title: 'Create Your First Exam',
        description: 'Set up an exam schedule for your school.',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFFEF4444),
        route: '/admin/exams',
      ),
      ChecklistStep(
        id: ChecklistStepId.addNotice,
        title: 'Post a School Notice',
        description: 'Announce something to teachers and students.',
        icon: Icons.announcement_rounded,
        color: const Color(0xFFF59E0B),
        route: '/admin/notices',
      ),
      ChecklistStep(
        id: ChecklistStepId.setupRoutine,
        title: 'Set Up Class Routine',
        description: 'Create a weekly timetable for each class.',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF8B5CF6),
        route: '/admin/routine',
      ),
      ChecklistStep(
        id: ChecklistStepId.exploreAttendance,
        title: 'Explore Attendance Tracking',
        description: 'Mark & monitor teacher and student attendance.',
        icon: Icons.how_to_reg_rounded,
        color: const Color(0xFF059669),
        route: '/admin/attendance',
      ),
    ];
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDismissed = prefs.getBool(_checklistDismissedKey) ?? false;
    _isAllCompleted = prefs.getBool(_checklistCompletedKey) ?? false;

    for (final step in steps) {
      final key = '$_prefKeyPrefix${step.id.name}';
      step.isCompleted = prefs.getBool(key) ?? false;
    }

    _isLoaded = true;
    _recalcCompleted();
    notifyListeners();
  }

  Future<void> markStepComplete(ChecklistStepId id) async {
    final step = steps.firstWhere((s) => s.id == id);
    if (step.isCompleted) return;

    step.isCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefKeyPrefix${id.name}', true);
    _recalcCompleted();
    notifyListeners();
  }

  Future<void> dismiss() async {
    _isDismissed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_checklistDismissedKey, true);
    notifyListeners();
  }

  void _recalcCompleted() {
    final allDone = steps.every((s) => s.isCompleted);
    if (allDone && !_isAllCompleted) {
      _isAllCompleted = true;
      _saveAllCompleted();
    }
  }

  Future<void> _saveAllCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_checklistCompletedKey, true);
  }

  int get completedCount => steps.where((s) => s.isCompleted).length;
  int get totalCount => steps.length;
  double get progress => completedCount / totalCount;

  /// Call this after a teacher is successfully added
  void onTeacherAdded() => markStepComplete(ChecklistStepId.addTeacher);

  /// Call this after a student is successfully enrolled
  void onStudentAdded() => markStepComplete(ChecklistStepId.addStudent);

  /// Call this when admin visits setup screen
  void onClassReviewed() => markStepComplete(ChecklistStepId.addClass);

  /// Call this after an exam is created
  void onExamCreated() => markStepComplete(ChecklistStepId.addExam);

  /// Call this after a notice is posted
  void onNoticePosted() => markStepComplete(ChecklistStepId.addNotice);

  /// Call this after routine is set up
  void onRoutineSetup() => markStepComplete(ChecklistStepId.setupRoutine);

  /// Call this when admin visits attendance screen
  void onAttendanceExplored() =>
      markStepComplete(ChecklistStepId.exploreAttendance);
}
