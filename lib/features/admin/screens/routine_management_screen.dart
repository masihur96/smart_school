import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/screens/class_detail_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/teacher_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/school_models.dart' hide Teacher;
import '../../auth/providers/auth_provider.dart';
import '../../teacher/providers/homework_provider.dart';
import '../providers/attendance_management_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/teacher_provider.dart';
import 'routine_pdf_preview_screen.dart';

// Day order constant
const _days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

// Day abbreviations for the tab
const _dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// Per-day accent colours
const _dayColors = [
  Color(0xFF7C3AED), // Mon – purple
  Color(0xFF2563EB), // Tue – blue
  Color(0xFF059669), // Wed – green
  Color(0xFFD97706), // Thu – amber
  Color(0xFFDC2626), // Fri – red
  Color(0xFF0891B2), // Sat – cyan
  Color(0xFF7C3AED), // Sun – purple
];

/// Formats a time string (e.g. "14:00:00", "14:00", "09:00:00") into a 12-hour format with AM/PM (e.g. "02:00 PM", "09:00 AM").
String _formatTime12Hour(String? timeStr) {
  if (timeStr == null || timeStr.trim().isEmpty) return '';
  try {
    final clean = timeStr.trim();
    final upper = clean.toUpperCase();
    final isPm = upper.contains('PM');
    final isAm = upper.contains('AM');

    final numOnly = clean.replaceAll(RegExp(r'[^\d:]'), '').trim();
    final parts = numOnly.split(':');
    if (parts.isEmpty || parts[0].isEmpty) return timeStr;

    int hour = int.parse(parts[0]);
    int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

    String period = '';
    if (isPm || isAm) {
      period = isPm ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
    } else {
      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) hour -= 12;
      } else {
        period = 'AM';
        if (hour == 0) hour = 12;
      }
    }

    final hStr = hour.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');

    return '$hStr:$mStr $period';
  } catch (_) {
    return timeStr;
  }
}

class RoutineManagementScreen extends StatefulWidget {
  const RoutineManagementScreen({super.key});

  @override
  State<RoutineManagementScreen> createState() =>
      _RoutineManagementScreenState();
}

class _RoutineManagementScreenState extends State<RoutineManagementScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedClassId;
  String? _selectedSectionId;
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialDayIndex = (_selectedDate.weekday - 1).clamp(
      0,
      _days.length - 1,
    );
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: initialDayIndex,
    );
    _tabController.addListener(_onTabChanged);

    // Try to auto-select if data is already available in the provider
    final classNotifier = context.read<ClassSetupNotifier>();
    final sectionNotifier = context.read<SectionSetupNotifier>();
    if (classNotifier.classes.isNotEmpty) {
      _selectedClassId = classNotifier.classes.first.id;
      final filteredSections = sectionNotifier.sections
          .where((s) => s.classId == _selectedClassId)
          .toList();
      if (filteredSections.isNotEmpty) {
        _selectedSectionId = filteredSections.first.id;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authNotifier = context.read<AuthNotifier>();
      final schoolId = authNotifier.user?.schoolId;

      if (schoolId != null) {
        log('Initiating data fetch for routine management: schoolId=$schoolId');

        // Fetch classes and sections first to enable auto-selection if not already selected
        await Future.wait([
          classNotifier.fetchClasses(schoolId),
          sectionNotifier.fetchSections(),
        ]);

        if (mounted &&
            _selectedClassId == null &&
            classNotifier.classes.isNotEmpty) {
          setState(() {
            _selectedClassId = classNotifier.classes.first.id;
            final filteredSections = sectionNotifier.sections
                .where((s) => s.classId == _selectedClassId)
                .toList();
            if (filteredSections.isNotEmpty) {
              _selectedSectionId = filteredSections.first.id;
            }
          });
        }

        // Fetch other dependencies
        if (mounted) {
          Future.wait([
            context.read<SubjectSetupNotifier>().fetchSubjects(schoolId),
            context.read<TeachersNotifier>().fetchTeachers(),
            context.read<RoutineNotifier>().fetchAllRoutines(schoolId),
          ]);
          _loadCompletionData();
        }
      } else {
        log(
          'Warning: No schoolId found in AuthNotifier during routine management init',
        );
      }
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final targetWeekday = _tabController.index + 1;
      if (_selectedDate.weekday != targetWeekday) {
        final diff = targetWeekday - _selectedDate.weekday;
        setState(() {
          _selectedDate = _selectedDate.add(Duration(days: diff));
        });
        _loadCompletionData();
      }
    }
  }

  void _loadCompletionData() {
    if (_selectedClassId == null) return;
    context.read<AttendanceManagementProvider>().fetchStudentAttendance(
      classId: _selectedClassId,
      sectionId: _selectedSectionId,
      startDate: _selectedDate,
      endDate: _selectedDate,
    );
    context.read<HomeworkNotifier>().fetchAdminHomework(
      classId: _selectedClassId,
      sectionId: _selectedSectionId,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
  }

  void _changeDateBy(int days) {
    final newDate = _selectedDate.add(Duration(days: days));
    setState(() {
      _selectedDate = newDate;
      final newTabIndex = (newDate.weekday - 1).clamp(0, _days.length - 1);
      if (_tabController.index != newTabIndex) {
        _tabController.animateTo(newTabIndex);
      }
    });
    _loadCompletionData();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryAdmin),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        final newTabIndex = (picked.weekday - 1).clamp(0, _days.length - 1);
        if (_tabController.index != newTabIndex) {
          _tabController.animateTo(newTabIndex);
        }
      });
      _loadCompletionData();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthNotifier>().user;

    final rawClasses = context
        .watch<ClassSetupNotifier>()
        .classes
        .where((c) => c.schoolId == user?.schoolId)
        .toList();
    final classes = rawClasses
        .fold<Map<String, ClassRoom>>({}, (map, c) {
          map[c.id] = c;
          return map;
        })
        .values
        .toList();

    final sections = context.watch<SectionSetupNotifier>().sections;
    final filteredSections = sections
        .where((s) => s.classId == _selectedClassId)
        .fold<Map<String, Section>>({}, (map, s) {
          map[s.id] = s;
          return map;
        })
        .values
        .toList();

    if (_selectedClassId != null &&
        !classes.any((c) => c.id == _selectedClassId)) {
      // Defer state update until after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedClassId = null);
      });
    }
    if (_selectedSectionId != null &&
        !filteredSections.any((s) => s.id == _selectedSectionId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedSectionId = null);
      });
    }

    final validClassId = classes.any((c) => c.id == _selectedClassId)
        ? _selectedClassId
        : null;

    final bool isFiltered = validClassId != null;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildSliverHeader(context, classes, filteredSections),
        ],
        body: isFiltered ? _buildTimetableBody() : _buildEmptyState(),
      ),
      floatingActionButton: isFiltered
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEntrySheet(context),
              backgroundColor: AppColors.primaryAdmin,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Entry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildSliverHeader(
    BuildContext context,
    List<ClassRoom> classes,
    List<Section> filteredSections,
  ) {
    final user = context.read<AuthNotifier>().user;

    final validClassId = classes.any((c) => c.id == _selectedClassId)
        ? _selectedClassId
        : null;
    final validSectionId =
        filteredSections.any((s) => s.id == _selectedSectionId)
        ? _selectedSectionId
        : null;

    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: user?.role.name.toLowerCase() == "admin"
          ? AppColors.primaryAdmin
          : AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_rounded),
          tooltip: 'Generate / Print Routine PDF',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoutinePdfPreviewScreen(
                  initialClassId: validClassId,
                  initialSectionId: validSectionId,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Class Routine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage weekly timetable for each class',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned(
              left: 20,
              right: 20,
              bottom: 60,
              child: Row(
                children: [
                  Expanded(
                    child: _FilterDropdown(
                      hint: 'Select Class',
                      value: validClassId,
                      items: classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() {
                        _selectedClassId = val;
                        _selectedSectionId = null;
                        _loadCompletionData();
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FilterDropdown(
                      hint: filteredSections.isEmpty
                          ? 'No Sections'
                          : 'All Sections',
                      value: validSectionId,
                      items: [
                        if (filteredSections.isNotEmpty)
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Sections'),
                          ),
                        ...filteredSections.map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        ),
                      ],
                      onChanged: filteredSections.isEmpty
                          ? null
                          : (val) => setState(() {
                              _selectedSectionId = val;
                              _loadCompletionData();
                            }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: (validClassId != null)
          ? TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: _dayAbbr.map((d) => Tab(text: d)).toList(),
            )
          : null,
    );
  }

  // ─── Timetable body ───────────────────────────────────────────────────────

  Widget _buildTimetableBody() {
    return Column(
      children: [
        _buildDateSelectorBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(_days.length, (dayIndex) {
              final day = _days[dayIndex];
              final color = _dayColors[dayIndex];
              return _DayRoutineTab(
                day: day,
                color: color,
                classId: _selectedClassId!,
                sectionId: _selectedSectionId ?? '',
                selectedDate: _selectedDate,
              );
            }),
          ),
        ),
      ],
    );
  }

  // ─── Date Selector Bar ───────────────────────────────────────────────────

  Widget _buildDateSelectorBar() {
    final df = DateFormat('EEE, d MMM yyyy');
    final dateStr = df.format(_selectedDate);
    final now = DateTime.now();
    final isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    // Calculate completed vs total for current day's routine
    final stateMap = context.watch<RoutineNotifier>().state;
    final List<RoutineEntry> allEntries;
    if (_selectedSectionId == null || _selectedSectionId!.isEmpty) {
      allEntries = stateMap.entries
          .where((e) => e.key.startsWith('${_selectedClassId}_'))
          .expand((e) => e.value)
          .toList();
    } else {
      final key = '${_selectedClassId}_$_selectedSectionId';
      allEntries = stateMap[key] ?? <RoutineEntry>[];
    }
    final currentDay = _days[_tabController.index];
    final dayEntries = allEntries.where((e) => e.day == currentDay).toList();

    final attendanceRecords = context
        .watch<AttendanceManagementProvider>()
        .studentAttendance;

    int completedCount = 0;
    for (final entry in dayEntries) {
      final hasAttendance = attendanceRecords.any((a) {
        if (a.routineId.isNotEmpty &&
            entry.id != null &&
            entry.id!.isNotEmpty) {
          return a.routineId == entry.id;
        }
        final matchSubject = a.subjectId == entry.subjectId;
        final matchSection =
            (_selectedSectionId == null || _selectedSectionId!.isEmpty) ||
            a.sectionId == entry.sectionId;
        return matchSubject && matchSection;
      });
      if (hasAttendance) completedCount++;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.12)),
      ),
      child: Row(
        children: [
          // Previous day button
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Previous Day',
            onPressed: () => _changeDateBy(-1),
          ),
          const SizedBox(width: 4),

          // Date picker button
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        dateStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1E1B4B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Next day button
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Next Day',
            onPressed: () => _changeDateBy(1),
          ),
          const SizedBox(width: 8),

          // Daily Completion summary badge
          if (dayEntries.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: completedCount == dayEntries.length
                    ? const Color(0xFFE8F5E9)
                    : (completedCount > 0
                          ? const Color(0xFFEDE9FE)
                          : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: completedCount == dayEntries.length
                      ? const Color(0xFF81C784)
                      : (completedCount > 0
                            ? const Color(0xFF7C3AED).withOpacity(0.3)
                            : Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    completedCount == dayEntries.length
                        ? Icons.check_circle_rounded
                        : (completedCount > 0
                              ? Icons.incomplete_circle_rounded
                              : Icons.schedule_rounded),
                    size: 13,
                    color: completedCount == dayEntries.length
                        ? const Color(0xFF2E7D32)
                        : (completedCount > 0
                              ? const Color(0xFF7C3AED)
                              : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$completedCount/${dayEntries.length} Done',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: completedCount == dayEntries.length
                          ? const Color(0xFF2E7D32)
                          : (completedCount > 0
                                ? const Color(0xFF7C3AED)
                                : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_outlined, size: 50),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Class',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a class above\nto view or manage the routine.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─── Add Entry Bottom Sheet ───────────────────────────────────────────────

  void _showAddEntrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRoutineEntrySheet(
        classId: _selectedClassId!,
        sectionId: _selectedSectionId ?? '',
        initialDay: _days[_tabController.index],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day Routine Tab
// ─────────────────────────────────────────────────────────────────────────────

class _DayRoutineTab extends StatelessWidget {
  final String day;
  final Color color;
  final String classId;
  final String sectionId;
  final DateTime selectedDate;

  const _DayRoutineTab({
    required this.day,
    required this.color,
    required this.classId,
    required this.sectionId,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final routineNotifier = context.watch<RoutineNotifier>();
    final isLoading = routineNotifier.isLoading;
    final stateMap = routineNotifier.state;

    // Attendance and Homework watchers
    final attendanceProvider = context.watch<AttendanceManagementProvider>();
    final homeworkNotifier = context.watch<HomeworkNotifier>();

    final studentAttendance = attendanceProvider.studentAttendance;
    final homeworkRecords = homeworkNotifier.homeworkRecords;

    // ── Shimmer skeleton while loading ─────────────────────────────────────
    if (isLoading) {
      return _buildShimmerSkeleton(context);
    }

    // If sectionId is empty, show entries for ALL sections of this class
    final List<RoutineEntry> allEntries;
    if (sectionId.isEmpty) {
      allEntries = stateMap.entries
          .where((e) => e.key.startsWith('${classId}_'))
          .expand((e) => e.value)
          .toList();
    } else {
      final key = '${classId}_$sectionId';
      allEntries = stateMap[key] ?? <RoutineEntry>[];
    }
    final entries = allEntries.where((e) => e.day == day).toList();

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: color.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No classes on $day',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];

        final subjectName = context
            .read<SubjectSetupNotifier>()
            .subjects
            .firstWhere(
              (s) => s.id == entry.subjectId,
              orElse: () => Subject(id: '', name: 'Unknown Subject'),
            )
            .name;

        final teacher = context.read<TeachersNotifier>().teachers.firstWhere(
          (t) => t.userId == entry.teacherId,
          orElse: () => Teacher(
            userId: '',
            designation: 'N/A',
            classId: '',
            sectionId: '',
          ),
        );
        final teacherName = teacher.user?.name ?? 'Unknown Teacher';

        // ── Detect Attendance completion ─────────────────────────────────
        final entryAttendance = studentAttendance.where((a) {
          if (a.routineId.isNotEmpty &&
              entry.id != null &&
              entry.id!.isNotEmpty) {
            return a.routineId == entry.id;
          }
          final matchSubject = a.subjectId == entry.subjectId;
          final matchSection =
              (entry.sectionId == null || entry.sectionId!.isEmpty) ||
              a.sectionId == entry.sectionId;
          return matchSubject && matchSection;
        }).toList();

        final bool isAttendanceDone = entryAttendance.isNotEmpty;
        final int presentCount = entryAttendance
            .where((a) => a.status.toLowerCase() == 'present')
            .length;
        final int absentCount = entryAttendance
            .where((a) => a.status.toLowerCase() == 'absent')
            .length;
        final int lateCount = entryAttendance
            .where((a) => a.status.toLowerCase() == 'late')
            .length;
        final int leaveCount = entryAttendance
            .where((a) => a.status.toLowerCase() == 'leave')
            .length;

        // ── Detect Homework completion ───────────────────────────────────
        final entryHomework = homeworkRecords.where((h) {
          final matchSubject = h.subjectId == entry.subjectId;
          final matchSection =
              (entry.sectionId == null || entry.sectionId!.isEmpty) ||
              h.sectionId == entry.sectionId;
          final matchDate =
              (h.createdAt.year == selectedDate.year &&
                  h.createdAt.month == selectedDate.month &&
                  h.createdAt.day == selectedDate.day) ||
              (h.dueDate.year == selectedDate.year &&
                  h.dueDate.month == selectedDate.month &&
                  h.dueDate.day == selectedDate.day);
          return matchSubject && matchSection && matchDate;
        }).toList();

        final bool isHomeworkDone = entryHomework.isNotEmpty;
        final String? homeworkTitle = isHomeworkDone
            ? entryHomework.first.title
            : null;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClassDetailScreen(
                  classRoom: ClassRoom(
                    id: classId,
                    name: entry.classEntity?.name ?? "",
                  ),
                  routineId: entry.id ?? "",
                  sectionId: entry.sectionId,
                  subjectID: entry.subjectId,
                  initialDate: selectedDate,
                ),
              ),
            );
          },
          child: _RoutineEntryCard(
            entry: entry,
            subjectName: subjectName,
            teacherName: teacherName,
            accentColor: color,
            selectedDate: selectedDate,
            isAttendanceDone: isAttendanceDone,
            presentCount: presentCount,
            absentCount: absentCount,
            lateCount: lateCount,
            leaveCount: leaveCount,
            isHomeworkDone: isHomeworkDone,
            homeworkTitle: homeworkTitle,
            onView: () => _viewEntry(
              context,
              entry,
              subjectName,
              teacherName,
              color,
              isAttendanceDone,
              presentCount,
              absentCount,
              isHomeworkDone,
              homeworkTitle,
            ),
            onEdit: () => _editEntry(context, classId, sectionId, entry),
            onDelete: () => _deleteEntry(context, classId, sectionId, entry),
          ),
        );
      },
    );
  }

  // ── Shimmer skeleton ────────────────────────────────────────────────────
  Widget _buildShimmerSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color shimBase = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFE8E8E8);
    final Color shimHighlight = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFF8F8F8);
    final Color lineColor = isDark
        ? const Color(0xFF3D3D3D)
        : const Color(0xFFDEDEDE);
    final Color cardBorder = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEEEEEE);

    // Thin rounded text-line placeholder
    Widget line(double w, {double h = 11, double r = 30}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: lineColor,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    // Solid block (avatar, icon, badge)
    Widget block(double w, double h, {double r = 8}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: lineColor,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    // One skeleton card that mirrors _RoutineEntryCard
    Widget skeletonCard() => Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Time column skeleton ──────────────────────
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: lineColor.withOpacity(0.25),
                  border: Border(right: BorderSide(color: cardBorder)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    line(48, h: 16, r: 8), // start time
                    const SizedBox(height: 8),
                    block(1, 14, r: 1), // divider tick
                    const SizedBox(height: 8),
                    line(38, h: 12, r: 8), // end time
                  ],
                ),
              ),
              // ── Content column skeleton ───────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject name + 3-dot menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          line(140, h: 14, r: 8),
                          block(20, 20, r: 10),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Teacher icon + name
                      Row(
                        children: [
                          block(14, 14, r: 7),
                          const SizedBox(width: 6),
                          line(100, h: 11),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Room badge
                      block(80, 22, r: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Shimmer.fromColors(
      baseColor: shimBase,
      highlightColor: shimHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => skeletonCard(),
      ),
    );
  }

  void _viewEntry(
    BuildContext context,
    RoutineEntry entry,
    String subjectName,
    String teacherName,
    Color color,
    bool isAttendanceDone,
    int presentCount,
    int absentCount,
    bool isHomeworkDone,
    String? homeworkTitle,
  ) {
    final df = DateFormat('dd MMM yyyy');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: color),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.routineDetails),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.book_outlined, 'Subject', subjectName),
            const SizedBox(height: 12),
            _detailRow(Icons.person_outline_rounded, 'Teacher', teacherName),
            const SizedBox(height: 12),
            _detailRow(
              Icons.calendar_today_outlined,
              'Day & Date',
              '${entry.day} (${df.format(selectedDate)})',
            ),
            const SizedBox(height: 12),
            _detailRow(
              Icons.access_time_rounded,
              'Duration',
              '${_formatTime12Hour(entry.startTime)} - ${_formatTime12Hour(entry.endTime)}',
            ),
            if (entry.roomNumber != null) ...[
              const SizedBox(height: 12),
              _detailRow(
                Icons.meeting_room_outlined,
                'Room',
                entry.roomNumber!,
              ),
            ],
            const SizedBox(height: 12),
            _detailRow(
              Icons.how_to_reg_rounded,
              'Attendance Status',
              isAttendanceDone
                  ? 'Completed ($presentCount Present, $absentCount Absent)'
                  : 'Pending (Not Taken)',
            ),
            const SizedBox(height: 12),
            _detailRow(
              Icons.assignment_outlined,
              'Homework Status',
              isHomeworkDone
                  ? 'Assigned: ${homeworkTitle ?? "Yes"}'
                  : 'None Assigned',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.close),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAdmin,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassDetailScreen(
                    classRoom: ClassRoom(
                      id: classId,
                      name: entry.classEntity?.name ?? "",
                    ),
                    routineId: entry.id ?? "",
                    sectionId: entry.sectionId,
                    subjectID: entry.subjectId,
                    initialDate: selectedDate,
                  ),
                ),
              );
            },
            child: const Text('Manage Class'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editEntry(
    BuildContext context,
    String classId,
    String sectionId,
    RoutineEntry entry,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRoutineEntrySheet(
        classId: classId,
        sectionId: (entry.sectionId != null && entry.sectionId!.isNotEmpty)
            ? entry.sectionId!
            : sectionId,
        initialDay: entry.day,
        existingEntry: entry,
      ),
    );
  }

  void _deleteEntry(
    BuildContext context,
    String classId,
    String sectionId,
    RoutineEntry entry,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteEntry),
        content: const Text(
          'Are you sure you want to delete this routine entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (entry.id != null) {
                context.read<RoutineNotifier>().removeRoutineFromAPI(
                  classId,
                  sectionId,
                  entry.id!,
                );
              } else {
                // Fallback for entries not yet synced/without ID (if any)
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Routine Entry Card
// ─────────────────────────────────────────────────────────────────────────────

class _RoutineEntryCard extends StatelessWidget {
  final RoutineEntry entry;
  final String subjectName;
  final String teacherName;
  final Color accentColor;
  final DateTime selectedDate;
  final bool isAttendanceDone;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int leaveCount;
  final bool isHomeworkDone;
  final String? homeworkTitle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const _RoutineEntryCard({
    required this.entry,
    required this.subjectName,
    required this.teacherName,
    required this.accentColor,
    required this.selectedDate,
    required this.isAttendanceDone,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.leaveCount = 0,
    required this.isHomeworkDone,
    this.homeworkTitle,
    required this.onDelete,
    required this.onEdit,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isAttendanceDone
              ? const Color(0xFF81C784).withOpacity(0.4)
              : Colors.grey.withOpacity(0.15),
          width: isAttendanceDone ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Time Indicator side
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isAttendanceDone
                      ? const Color(0xFFE8F5E9).withOpacity(0.6)
                      : accentColor.withOpacity(0.06),
                  border: Border(
                    right: BorderSide(
                      color: isAttendanceDone
                          ? const Color(0xFFA5D6A7).withOpacity(0.5)
                          : accentColor.withOpacity(0.12),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime12Hour(entry.startTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 1,
                      height: 10,
                      color: accentColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime12Hour(entry.endTime),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Colors.grey[700],
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Subject Name + Completion Symbol/Badge + 3-Dot Menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusBadge(),
                          _buildActionsMenu(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Teacher Info & Attachment
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              teacherName,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.fileUrl != null)
                            IconButton(
                              onPressed: () async {
                                final url = Uri.parse(entry.fileUrl!);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(
                                Icons.attach_file_rounded,
                                size: 18,
                                color: AppColors.primaryAdmin,
                              ),
                              tooltip: 'View Attachment',
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Status Symbols & Badges Row (Attendance, Homework, Room)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // ── Attendance Symbol Chip ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isAttendanceDone
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: isAttendanceDone
                                    ? const Color(0xFFA5D6A7)
                                    : const Color(0xFFFECDD3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAttendanceDone
                                      ? Icons.how_to_reg_rounded
                                      : Icons.person_off_outlined,
                                  size: 12,
                                  color: isAttendanceDone
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFE11D48),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAttendanceDone
                                      ? (presentCount + absentCount > 0
                                            ? 'Attendance: $presentCount P / $absentCount A'
                                            : 'Attendance: Done')
                                      : 'Attendance: Pending',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isAttendanceDone
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFE11D48),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Homework Symbol Chip ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isHomeworkDone
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: isHomeworkDone
                                    ? const Color(0xFFC7D2FE)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isHomeworkDone
                                      ? Icons.assignment_turned_in_rounded
                                      : Icons.assignment_outlined,
                                  size: 12,
                                  color: isHomeworkDone
                                      ? const Color(0xFF4338CA)
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 120,
                                  ),
                                  child: Text(
                                    isHomeworkDone
                                        ? 'HW: ${homeworkTitle ?? "Added"}'
                                        : 'No HW',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isHomeworkDone
                                          ? const Color(0xFF4338CA)
                                          : Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Room Badge (if available) ──
                          if (entry.roomNumber != null &&
                              entry.roomNumber!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.meeting_room_outlined,
                                    size: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Room ${entry.roomNumber}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (isAttendanceDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF81C784)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 12,
              color: Color(0xFF2E7D32),
            ),
            const SizedBox(width: 3),
            Text(
              isHomeworkDone ? 'Done + HW' : 'Done',
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (isHomeworkDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7DD3FC)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_turned_in_rounded,
              size: 12,
              color: Color(0xFF0284C7),
            ),
            const SizedBox(width: 3),
            Text(
              'HW Added',
              style: TextStyle(
                color: Color(0xFF0284C7),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFEA580C)),
            const SizedBox(width: 3),
            Text(
              'Pending',
              style: TextStyle(
                color: Color(0xFFEA580C),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionsMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (val == 'view') onView();
        if (val == 'edit') onEdit();
        if (val == 'delete') onDelete();
      },
      itemBuilder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return [
          PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  size: 18,
                  color: Colors.blue,
                ),
                const SizedBox(width: 10),
                Text(l10n.viewDetails),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
                const SizedBox(width: 10),
                Text(l10n.edit),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.red,
                ),
                const SizedBox(width: 10),
                Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ];
      },
    );
  }
}

class _AddRoutineEntrySheet extends StatefulWidget {
  final String classId;
  final String sectionId;
  final String initialDay;
  final RoutineEntry? existingEntry;

  const _AddRoutineEntrySheet({
    required this.classId,
    required this.sectionId,
    required this.initialDay,
    this.existingEntry,
  });

  @override
  State<_AddRoutineEntrySheet> createState() => _AddRoutineEntrySheetState();
}

class _AddRoutineEntrySheetState extends State<_AddRoutineEntrySheet> {
  late Set<String> _selectedDays;
  String? _subjectId;
  String? _teacherId;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final _roomController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isEditMode => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _selectedDays = {widget.existingEntry!.day};
      _subjectId = widget.existingEntry!.subjectId;
      _teacherId = widget.existingEntry!.teacherId;
      _startTime = _parseTime(widget.existingEntry!.startTime);
      _endTime = _parseTime(widget.existingEntry!.endTime);
      _roomController.text = widget.existingEntry!.roomNumber ?? '';
    } else {
      _selectedDays = {widget.initialDay};
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final clean = timeStr.trim();
      final upper = clean.toUpperCase();
      final isPm = upper.contains('PM');
      final isAm = upper.contains('AM');

      final numOnly = clean.replaceAll(RegExp(r'[^\d:]'), '').trim();
      final parts = numOnly.split(':');
      if (parts.isEmpty || parts[0].isEmpty) {
        return const TimeOfDay(hour: 9, minute: 0);
      }

      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

      if (isPm && hour < 12) {
        hour += 12;
      } else if (isAm && hour == 12) {
        hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      log('Error parsing time: $timeStr');
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF7C3AED),
            onSurface: Color(0xFF1E1B4B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() async {
    log('Save button pressed in _AddRoutineEntrySheet');
    if (_subjectId == null || _teacherId == null) {
      log('Validation failed: subject or teacher not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pleaseSelectSubjectAndTeacher,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authNotifier = context.read<AuthNotifier>();
    final schoolId =
        authNotifier.user?.schoolId ?? '3b1e7e8f-6e4c-4c0e-9c2a-6d8f4c1b7a91';

    try {
      final teacherIds = context
          .read<TeachersNotifier>()
          .teachers
          .map((t) => t.userId)
          .where((id) => id.isNotEmpty)
          .toList();

      final classes = context.read<ClassSetupNotifier>().classes;
      final sections = context.read<SectionSetupNotifier>().sections;

      final className = classes
          .firstWhere(
            (c) => c.id == widget.classId,
            orElse: () => ClassRoom(id: '', name: widget.classId),
          )
          .name;
      final sectionName = sections
          .firstWhere(
            (s) => s.id == widget.sectionId,
            orElse: () => Section(id: '', name: widget.sectionId, classId: ''),
          )
          .name;

      final orderedSelectedDays = _days
          .where((d) => _selectedDays.contains(d))
          .toList();

      if (_isEditMode) {
        // In edit mode:
        // Update the existing entry for the primary day.
        final String updateDay =
            orderedSelectedDays.contains(widget.existingEntry!.day)
                ? widget.existingEntry!.day
                : orderedSelectedDays.first;

        final updatedEntry = RoutineEntry(
          id: widget.existingEntry!.id,
          classId: widget.classId,
          schoolId: schoolId,
          day: updateDay,
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          subjectId: _subjectId!,
          teacherId: _teacherId!,
          sectionId: widget.sectionId,
          roomNumber: _roomController.text.trim().isEmpty
              ? null
              : _roomController.text.trim(),
        );

        log('Calling updateRoutineOnAPI from UI for day: $updateDay');
        await context.read<RoutineNotifier>().updateRoutineOnAPI(
          widget.classId,
          widget.sectionId,
          updatedEntry,
          className: className,
          sectionName: sectionName,
          receiverUuids: teacherIds,
        );

        // Add additional selected days as new routine entries
        final additionalDays =
            orderedSelectedDays.where((d) => d != updateDay).toList();
        for (final day in additionalDays) {
          final newEntry = RoutineEntry(
            classId: widget.classId,
            schoolId: schoolId,
            day: day,
            startTime: _formatTime(_startTime),
            endTime: _formatTime(_endTime),
            subjectId: _subjectId!,
            teacherId: _teacherId!,
            sectionId: widget.sectionId,
            roomNumber: _roomController.text.trim().isEmpty
                ? null
                : _roomController.text.trim(),
          );
          log('Calling addRoutineToAPI for additional day: $day');
          await context.read<RoutineNotifier>().addRoutineToAPI(
            widget.classId,
            widget.sectionId,
            newEntry,
            className: className,
            sectionName: sectionName,
            receiverUuids: teacherIds,
          );
        }
      } else {
        // Add: create one entry per selected day
        for (final day in orderedSelectedDays) {
          final entry = RoutineEntry(
            classId: widget.classId,
            schoolId: schoolId,
            day: day,
            startTime: _formatTime(_startTime),
            endTime: _formatTime(_endTime),
            subjectId: _subjectId!,
            teacherId: _teacherId!,
            sectionId: widget.sectionId,
            roomNumber: _roomController.text.trim().isEmpty
                ? null
                : _roomController.text.trim(),
          );
          log('Calling addRoutineToAPI for day: $day');
          await context.read<RoutineNotifier>().addRoutineToAPI(
            widget.classId,
            widget.sectionId,
            entry,
            className: className,
            sectionName: sectionName,
            receiverUuids: teacherIds,
          );
        }
      }

      if (mounted) {
        log('Routine saved successfully, closing sheet');
        Navigator.pop(context);
        final count = _selectedDays.length;
        final msg = _isEditMode
            ? (count == 1
                ? AppLocalizations.of(context)!.routineEntryAdded
                : '$count routine entries updated & saved successfully!')
            : (count == 1
                ? AppLocalizations.of(context)!.routineEntryAdded
                : '$count routine entries saved successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      log('Error saving routine entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorLabel(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectSetupNotifier>().subjects;
    final teachers = context.watch<TeachersNotifier>().teachers;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),                                              v
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isEditMode
                          ? Icons.edit_calendar_rounded
                          : Icons.add_alarm_rounded,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditMode
                            ? 'Edit Routine Entry'
                            : 'Add Routine Entry',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isEditMode
                            ? (_selectedDays.length > 1
                                ? 'Update and apply to selected days'
                                : 'Update the details below')
                            : 'Select days & fill in the details',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Day Selector ──
                      Row(
                        children: [
                          const _SectionLabel(
                            icon: Icons.calendar_today_outlined,
                            label: 'Select Day',
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _selectedDays.isEmpty
                                  ? 'None selected'
                                  : '${_selectedDays.length} selected',
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _days.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final d = _days[i];
                            final isSelected = _selectedDays.contains(d);
                            final color = _dayColors[i];
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (isSelected && _selectedDays.length > 1) {
                                  _selectedDays = Set.from(_selectedDays)
                                    ..remove(d);
                                } else if (!isSelected) {
                                  _selectedDays = Set.from(_selectedDays)
                                    ..add(d);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color
                                      : color.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : color.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(
                                        Icons.check_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      _dayAbbr[i],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => setState(
                              () => _selectedDays = Set.from(_days),
                            ),
                            child: const Text(
                              'Select All',
                              style: TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(
                              () => _selectedDays = {
                                _isEditMode
                                    ? widget.existingEntry!.day
                                    : widget.initialDay,
                              },
                            ),
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Subject ──
                      const _SectionLabel(
                        icon: Icons.menu_book_rounded,
                        label: 'Subject',
                      ),
                      const SizedBox(height: 10),
                      _SearchableSubjectDropdown(
                        subjects: {
                          for (final s in subjects) s.name: s,
                        }.values.toList(),
                        selectedId: _subjectId,
                        onChanged: (val) => setState(() => _subjectId = val),
                      ),
                      const SizedBox(height: 16),

                      // ── Teacher ──
                      const _SectionLabel(
                        icon: Icons.person_outline_rounded,
                        label: 'Teacher',
                      ),
                      const SizedBox(height: 10),
                      _SearchableTeacherDropdown(
                        teachers: teachers,
                        selectedId: _teacherId,
                        onChanged: (val) => setState(() => _teacherId = val),
                      ),
                      const SizedBox(height: 24),

                      // ── Time ──
                      const _SectionLabel(
                        icon: Icons.access_time_rounded,
                        label: 'Time Slot',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _TimePicker(
                              label: 'Start Time',
                              time: _startTime,
                              onTap: () => _pickTime(isStart: true),
                              accentColor: const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimePicker(
                              label: 'End Time',
                              time: _endTime,
                              onTap: () => _pickTime(isStart: false),
                              accentColor: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Room Number (optional) ──
                      const _SectionLabel(
                        icon: Icons.room_outlined,
                        label: 'Room Number (Optional)',
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _roomController,
                        decoration: InputDecoration(
                          hintText: 'e.g. 101, Lab-A',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFEDE9FE),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFEDE9FE),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF7C3AED),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ── Save Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed:
                                context.watch<RoutineNotifier>().isLoading
                                ? null
                                : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAdmin,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: context.watch<RoutineNotifier>().isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isEditMode
                                            ? (_selectedDays.length > 1
                                                  ? 'Update & Save ${_selectedDays.length} Entries'
                                                  : 'Update Entry')
                                            : (_selectedDays.length > 1
                                                  ? 'Save ${_selectedDays.length} Entries'
                                                  : 'Save Entry'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// A searchable subject picker backed by [DropdownSearch].
class _SearchableSubjectDropdown extends StatelessWidget {
  final List<dynamic> subjects; // list of Subject objects
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _SearchableSubjectDropdown({
    required this.subjects,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Find the currently selected subject object (if any)
    final selectedSubject = subjects.cast<dynamic>().firstWhere(
      (s) => s.id == selectedId,
      orElse: () => null,
    );

    return DropdownSearch<dynamic>(
      items: (filter, _) => subjects
          .where((s) => s.name.toLowerCase().contains(filter.toLowerCase()))
          .toList(),
      selectedItem: selectedSubject,
      compareFn: (a, b) => a?.id == b?.id,
      itemAsString: (s) => s.name as String,
      onSelected: (s) => onChanged(s?.id as String?),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          hintText: 'Choose a subject',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEDE9FE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: selectedId != null
                  ? const Color(0xFF7C3AED).withOpacity(0.4)
                  : const Color(0xFFEDE9FE),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
          suffixIcon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF7C3AED),
          ),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchDelay: Duration.zero,
        constraints: const BoxConstraints(maxHeight: 300),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search subject...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF7C3AED),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F3FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        menuProps: MenuProps(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
          shadowColor: const Color(0xFF7C3AED).withOpacity(0.15),
        ),
        itemBuilder: (context, item, isSelected, isHighlighted) => ListTile(
          dense: true,
          title: Text(
            item.name as String,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFF1E1B4B),
            ),
          ),
          trailing: isSelected
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF7C3AED),
                  size: 18,
                )
              : null,
          tileColor: isSelected
              ? const Color(0xFF7C3AED).withOpacity(0.06)
              : null,
        ),
      ),
    );
  }
}

/// A searchable teacher picker with avatar + name + designation per item.
class _SearchableTeacherDropdown extends StatelessWidget {
  final List<dynamic> teachers;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _SearchableTeacherDropdown({
    required this.teachers,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTeacher = teachers.cast<dynamic>().firstWhere(
      (t) => t.userId == selectedId,
      orElse: () => null,
    );

    return DropdownSearch<dynamic>(
      items: (filter, _) => teachers
          .where(
            (t) => (t.user?.name ?? 'Unknown').toLowerCase().contains(
              filter.toLowerCase(),
            ),
          )
          .toList(),
      selectedItem: selectedTeacher,
      compareFn: (a, b) => a?.userId == b?.userId,
      itemAsString: (t) => t.user?.name as String? ?? 'Unknown',
      onSelected: (t) => onChanged(t?.userId as String?),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          hintText: 'Assign a teacher',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEDE9FE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: selectedId != null
                  ? const Color(0xFF7C3AED).withOpacity(0.4)
                  : const Color(0xFFEDE9FE),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
          suffixIcon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF7C3AED),
          ),
        ),
      ),
      dropdownBuilder: (context, selectedItem) {
        if (selectedItem == null) return const SizedBox.shrink();
        final name = selectedItem.user?.name as String? ?? 'Unknown';
        final avatar = selectedItem.user?.avatar as String?;
        final designation = selectedItem.designation as String? ?? '';
        return Row(
          children: [
            _TeacherAvatar(avatar: avatar, name: name, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1B4B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (designation.isNotEmpty)
                    Text(
                      designation,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        );
      },
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchDelay: Duration.zero,
        constraints: const BoxConstraints(maxHeight: 320),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search teacher...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF7C3AED),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F3FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        menuProps: MenuProps(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
          shadowColor: const Color(0xFF7C3AED).withOpacity(0.15),
        ),
        itemBuilder: (context, item, isSelected, isHighlighted) {
          final name = item.user?.name as String? ?? 'Unknown';
          final avatar = item.user?.avatar as String?;
          final designation = item.designation as String? ?? '';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isSelected
                ? const Color(0xFF7C3AED).withOpacity(0.06)
                : null,
            child: Row(
              children: [
                _TeacherAvatar(avatar: avatar, name: name, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF1E1B4B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (designation.isNotEmpty)
                        Text(
                          designation,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF7C3AED),
                    size: 18,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Circular avatar with network image + graceful fallback initials.
class _TeacherAvatar extends StatelessWidget {
  final String? avatar;
  final String name;
  final double size;

  const _TeacherAvatar({
    required this.avatar,
    required this.name,
    required this.size,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatar != null && avatar!.isNotEmpty;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF7C3AED).withOpacity(0.12),
      backgroundImage: hasAvatar
          ? CachedNetworkImageProvider(
              avatar!,
              cacheKey: avatar!.split('?').first,
            )
          : null,
      onBackgroundImageError: hasAvatar ? (_, __) {} : null,
      child: hasAvatar
          ? null
          : Text(
              _initials,
              style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7C3AED),
              ),
            ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        // color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          // dropdownColor: const Color(0xFF4F46E5),
          // style: TextStyle(color: Colors.white, fontSize: 13),
          hint: Text(hint),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.black,
            size: 18,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? const Color(0xFF7C3AED).withOpacity(0.4)
              : const Color(0xFFEDE9FE),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF7C3AED)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  final Color accentColor;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
    required this.accentColor,
  });

  String get _formattedTime {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  _formattedTime,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
