import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/models/teacher_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/teacher_provider.dart';
import '../../../models/school_models.dart';

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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authNotifier = context.read<AuthNotifier>();
      final schoolId = authNotifier.user?.schoolId;

      if (schoolId != null) {
        log('Initiating data fetch for routine management: schoolId=$schoolId');
        context.read<SubjectSetupNotifier>().fetchSubjects(schoolId);
        context.read<TeachersNotifier>().fetchTeachers();
      } else {
        log('Warning: No schoolId found in AuthNotifier during routine management init');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;
    final filteredSections = sections
        .where((s) => s.classId == _selectedClassId)
        .toList();

    final bool isFiltered =
        _selectedClassId != null && _selectedSectionId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildSliverHeader(context, classes, filteredSections),
        ],
        body: isFiltered
            ? _buildTimetableBody()
            : _buildEmptyState(),
      ),
      floatingActionButton: isFiltered
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEntrySheet(context),
              backgroundColor: const Color(0xFF7C3AED),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Entry',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF7C3AED),
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
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
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // Filter row
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown(
                          hint: 'Select Class',
                          value: _selectedClassId,
                          items: classes
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (val) => setState(() {
                            _selectedClassId = val;
                            _selectedSectionId = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FilterDropdown(
                          hint: 'Select Section',
                          value: _selectedSectionId,
                          items: filteredSections
                              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedSectionId = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: (_selectedClassId != null && _selectedSectionId != null)
          ? TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: _dayAbbr.map((d) => Tab(text: d)).toList(),
            )
          : null,
    );
  }

  // ─── Timetable body ───────────────────────────────────────────────────────

  Widget _buildTimetableBody() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(_days.length, (dayIndex) {
        final day = _days[dayIndex];
        final color = _dayColors[dayIndex];
        return _DayRoutineTab(
          day: day,
          color: color,
          classId: _selectedClassId!,
          sectionId: _selectedSectionId!,
        );
      }),
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
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 50,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Class & Section',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a class and section above\nto view or manage the routine.',
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
        sectionId: _selectedSectionId!,
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

  const _DayRoutineTab({
    required this.day,
    required this.color,
    required this.classId,
    required this.sectionId,
  });

  @override
  Widget build(BuildContext context) {
    final key = '${classId}_$sectionId';
    final allEntries =
        context.watch<RoutineNotifier>().state[key] ?? <RoutineEntry>[];
    final entries =
        allEntries.where((e) => e.day == day).toList();

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 48, color: color.withOpacity(0.4)),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        // Find global index for delete
        final globalIndex = allEntries.indexOf(entry);

        final subjectName = context
            .read<SubjectSetupNotifier>()
            .subjects
            .firstWhere(
              (s) => s.id == entry.subjectId,
              orElse: () => Subject(id: '', name: 'Unknown Subject'),
            )
            .name;

        final teacher = context
            .read<TeachersNotifier>()
            .teachers
            .firstWhere(
              (t) => t.userId == entry.teacherId,
              orElse: () => Teacher(
                userId: '',
                designation: 'N/A',
                classId: '',
                sectionId: '',
              ),
            );
        final teacherName = teacher.user?.name ?? 'Unknown Teacher';

        return _RoutineEntryCard(
          entry: entry,
          subjectName: subjectName,
          teacherName: teacherName,
          accentColor: color,
          onDelete: () {
            context.read<RoutineNotifier>().removeEntry(
              classId,
              sectionId,
              globalIndex,
            );
          },
        );
      },
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
  final VoidCallback onDelete;

  const _RoutineEntryCard({
    required this.entry,
    required this.subjectName,
    required this.teacherName,
    required this.accentColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Accent side bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subjectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  teacherName,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (entry.roomNumber != null &&
                              entry.roomNumber!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.room_outlined,
                                    size: 13, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  'Room ${entry.roomNumber}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Time pill + delete
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry.startTime}\n${entry.endTime}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _confirmDelete(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Colors.red[300],
                            ),
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
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Entry'),
        content: Text('Remove "$subjectName" from the routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Routine Entry Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddRoutineEntrySheet extends StatefulWidget {
  final String classId;
  final String sectionId;
  final String initialDay;

  const _AddRoutineEntrySheet({
    required this.classId,
    required this.sectionId,
    required this.initialDay,
  });

  @override
  State<_AddRoutineEntrySheet> createState() => _AddRoutineEntrySheetState();
}

class _AddRoutineEntrySheetState extends State<_AddRoutineEntrySheet> {
  late String _selectedDay;
  String? _subjectId;
  String? _teacherId;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final _roomController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
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
        const SnackBar(
          content: Text('Please select subject and teacher.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authNotifier = context.read<AuthNotifier>();
    final schoolId = authNotifier.user?.schoolId ?? '3b1e7e8f-6e4c-4c0e-9c2a-6d8f4c1b7a91';
    
    final entry = RoutineEntry(
      classId: widget.classId,
      schoolId: schoolId,
      day: _selectedDay,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      subjectId: _subjectId!,
      teacherId: _teacherId!,
      roomNumber: _roomController.text.trim().isEmpty
          ? null
          : _roomController.text.trim(),
    );

    log('Routine entry created: ${entry.toJson()}');

    try {
      log('Calling addRoutineToAPI from UI');
      await context.read<RoutineNotifier>().addRoutineToAPI(
        widget.classId,
        widget.sectionId,
        entry,
      );
      if (mounted) {
        log('Routine added successfully, closing sheet');
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Routine entry added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      log('Error adding routine entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                    child: const Icon(
                      Icons.add_alarm_rounded,
                      color: Color(0xFF7C3AED),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Routine Entry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      Text(
                        'Fill in the details below',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
                      const _SectionLabel(
                        icon: Icons.calendar_today_outlined,
                        label: 'Select Day',
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
                            final isSelected = d == _selectedDay;
                            final color = _dayColors[i];
                            return GestureDetector(
                              onTap: () => setState(() => _selectedDay = d),
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
                                child: Text(
                                  _dayAbbr[i],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Subject ──
                      const _SectionLabel(
                        icon: Icons.menu_book_rounded,
                        label: 'Subject',
                      ),
                      const SizedBox(height: 10),
                      _StyledDropdown<String>(
                        hint: 'Choose a subject',
                        value: _subjectId,
                        items: subjects
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _subjectId = val),
                      ),
                      const SizedBox(height: 16),

                      // ── Teacher ──
                      const _SectionLabel(
                        icon: Icons.person_outline_rounded,
                        label: 'Teacher',
                      ),
                      const SizedBox(height: 10),
                      _StyledDropdown<String>(
                        hint: 'Assign a teacher',
                        value: _teacherId,
                        items: teachers
                            .map((t) => DropdownMenuItem(
                                  value: t.userId,
                                  child: Text(t.user?.name ?? 'Unknown'),
                                ))
                            .toList(),
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
                          fillColor: const Color(0xFFF8F7FF),
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
                      const SizedBox(height: 32),

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
                                color: const Color(0xFF7C3AED).withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: context.watch<RoutineNotifier>().isLoading
                                ? null
                                : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
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
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Save Entry',
                                        style: TextStyle(
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

class _FilterDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF4F46E5),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          hint: Text(hint, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
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
        Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1E1B4B),
          ),
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
        color: const Color(0xFFF8F7FF),
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
          hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
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
