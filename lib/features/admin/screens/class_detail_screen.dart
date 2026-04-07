import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/teacher/providers/attendance_provider.dart';
import '../../../models/school_models.dart';
import '../../../models/student_model.dart';
import '../providers/student_provider.dart';
import '../providers/setup_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teacher/providers/homework_provider.dart';

// ─── Colour palette (shared) ─────────────────────────────────────────────────
const _kPrimary = Color(0xFF6C3CE1);
const _kBg = Color(0xFFF4F2FB);
const _kDivider = Color(0xFFEDE9F8);

// ─────────────────────────────────────────────────────────────────────────────
// ClassDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class ClassDetailScreen extends StatefulWidget {
  final ClassRoom classRoom;
  final String? subjectID;
  final String? sectionId;

  const ClassDetailScreen({super.key, this.subjectID, required this.classRoom, this.sectionId});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  // Attendance state: studentId → status
  final Map<String, AttendanceStatus> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load students for this class + section
      context.read<StudentsNotifier>().fetchStudentsBySection(
            classId: widget.classRoom.id,
            sectionId: widget.sectionId,
          );
      // Ensure subjects are loaded for homework
      final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
      if (schoolId.isNotEmpty) {
        context.read<SubjectSetupNotifier>().fetchSubjects(schoolId);
      }

      // Load homework for this class
      context.read<HomeworkNotifier>().fetchHomework(
            classId: widget.classRoom.id,
            sectionId: widget.sectionId,
            subjectId: widget.subjectID,
          );
      
      _loadAttendanceForDate();
    });
  }

  Future<void> _loadAttendanceForDate() async {
    await context.read<AttendanceNotifier>().fetchAttendanceFromAPI(
          classId: widget.classRoom.id,
          sectionId: widget.sectionId,
          date: _selectedDate,
        );

    if (mounted) {
      final records = context
          .read<AttendanceNotifier>()
          .getRecordsForDate(_selectedDate);
      setState(() {
        _attendanceMap.clear();
        for (var record in records) {
          _attendanceMap[record.studentId] = record.status;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Date picker ─────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF7C3AED)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadAttendanceForDate();
    }
  }

  // ── Save attendance ──────────────────────────────────────────────────────────

  Future<void> _saveAttendance() async {
    final authNotifier = context.read<AuthNotifier>();
    final teacherId = authNotifier.user?.id;
    if (teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No active user found.')),
      );
      return;
    }

    final students = context.read<StudentsNotifier>().students;

    // Ensure all students have a status in the map (defaulting to present)
    final fullMap = <String, AttendanceStatus>{};
    for (var student in students) {
      fullMap[student.userId] =
          _attendanceMap[student.userId] ?? AttendanceStatus.present;
    }

    final success = await context.read<AttendanceNotifier>().submitAttendanceToAPI(
      date: _selectedDate,
      takenBy: teacherId,
      classId: widget.classRoom.id,
      sectionId: widget.sectionId,
      attendanceMap: fullMap,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved successfully!'),
          backgroundColor: Color(0xFF7C3AED),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save attendance.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 160,
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
                    colors: [Color(0xFF6C3CE1), Color(0xFF9B6DFF)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.classRoom.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.classRoom.description.isNotEmpty
                              ? widget.classRoom.description
                              : 'Class details & management',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.how_to_reg), text: 'Attendance'),
                Tab(icon: Icon(Icons.assignment), text: 'Homework'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _AttendanceTab(
              classRoom: widget.classRoom,
              sectionId: widget.sectionId,
              selectedDate: _selectedDate,
              dateLabel: dateLabel,
              attendanceMap: _attendanceMap,
              onPickDate: _pickDate,
              onSave: _saveAttendance,
              onStatusChanged: (studentId, status) {
                setState(() => _attendanceMap[studentId] = status);
              },
            ),
            _HomeworkTab(classRoom: widget.classRoom, sectionId: widget.sectionId),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance Tab
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceTab extends StatelessWidget {
  final ClassRoom classRoom;
  final String? sectionId;
  final DateTime selectedDate;
  final String dateLabel;
  final Map<String, AttendanceStatus> attendanceMap;
  final VoidCallback onPickDate;
  final VoidCallback onSave;
  final void Function(String studentId, AttendanceStatus status) onStatusChanged;

  const _AttendanceTab({
    required this.classRoom,
    this.sectionId,
    required this.selectedDate,
    required this.dateLabel,
    required this.attendanceMap,
    required this.onPickDate,
    required this.onSave,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final studentNotifier = context.watch<StudentsNotifier>();
    final attendanceNotifier = context.watch<AttendanceNotifier>();
    final isLoading = studentNotifier.isLoading || attendanceNotifier.isLoading;
    
    final students = studentNotifier.students;

    return Column(
      children: [
        // Date selector bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              const Text(
                'Date:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onPickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF7C3AED).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_drop_down,
                          size: 18, color: Color(0xFF7C3AED)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${students.length} students',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Student list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : students.isEmpty
                  ? _EmptyState(
                      icon: Icons.people_outline,
                      message: 'No students found in\n${classRoom.name}',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final status = attendanceMap[student.userId] ??
                            AttendanceStatus.present;
                        return _StudentAttendanceCard(
                          student: student,
                          status: status,
                          onChanged: (newStatus) =>
                              onStatusChanged(student.userId, newStatus),
                        );
                      },
                    ),
        ),

        // Save button
        if (!isLoading && students.isNotEmpty)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Save Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Student Attendance Card
// ─────────────────────────────────────────────────────────────────────────────

class _StudentAttendanceCard extends StatelessWidget {
  final Student student;
  final AttendanceStatus status;
  final void Function(AttendanceStatus) onChanged;

  const _StudentAttendanceCard({
    required this.student,
    required this.status,
    required this.onChanged,
  });

  Color get _statusColor {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.leave:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = student.user?.name ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: _kDivider.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: _statusColor.withOpacity(0.15),
              child: Text(
                initial,
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name & roll
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Roll: ${student.rollId}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            // Segmented toggle
            _AttendanceToggle(current: status, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance Toggle (Present / Absent / Leave)
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceToggle extends StatelessWidget {
  final AttendanceStatus current;
  final void Function(AttendanceStatus) onChanged;

  const _AttendanceToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleChip(
          label: 'P',
          tooltip: 'Present',
          active: current == AttendanceStatus.present,
          activeColor: Colors.green,
          onTap: () => onChanged(AttendanceStatus.present),
        ),
        const SizedBox(width: 4),
        _ToggleChip(
          label: 'A',
          tooltip: 'Absent',
          active: current == AttendanceStatus.absent,
          activeColor: Colors.red,
          onTap: () => onChanged(AttendanceStatus.absent),
        ),
        const SizedBox(width: 4),
        _ToggleChip(
          label: 'L',
          tooltip: 'Leave',
          active: current == AttendanceStatus.leave,
          activeColor: Colors.orange,
          onTap: () => onChanged(AttendanceStatus.leave),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.tooltip,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? activeColor : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Homework Tab
// ─────────────────────────────────────────────────────────────────────────────

class _HomeworkTab extends StatelessWidget {
  final ClassRoom classRoom;
  final String? sectionId;

  const _HomeworkTab({
    required this.classRoom,
    this.sectionId,
  });

  @override
  Widget build(BuildContext context) {
    final homeworkNotifier = context.watch<HomeworkNotifier>();
    final isLoading = homeworkNotifier.isLoading;
    final homeworkList = homeworkNotifier.homeworkRecords
        .where((h) => h.classId == classRoom.id)
        .toList();

    return Stack(
      children: [
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
            ),
          )
        else if (homeworkList.isEmpty)
          const _EmptyState(
            icon: Icons.assignment_outlined,
            message: 'No homework assigned yet.\nTap + to add one.',
          )
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: homeworkList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              final hw = homeworkList[index];
              final subjects =
                  context.read<SubjectSetupNotifier>().subjects;
              final subjectName = subjects
                  .firstWhere(
                    (s) => s.id == hw.subjectId,
                    orElse: () => Subject(id: '', name: 'Unknown Subject'),
                  )
                  .name;
              return _HomeworkCard(
                homework: hw,
                subjectName: subjectName,
                onView: () => _showViewSheet(ctx, hw, subjectName),
                onEdit: () => _showEditSheet(ctx, hw),
                onDelete: () => _confirmDelete(ctx, hw.id),
              );
            },
          ),

        // FAB
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'hw_fab',
            onPressed: () => _showAddSheet(context),
            backgroundColor: const Color(0xFF7C3AED),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Homework',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHomeworkSheet(
        classRoom: classRoom,
        sectionId: sectionId,
      ),
    );
  }

  void _showEditSheet(BuildContext context, Homework homework) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHomeworkSheet(
        classRoom: classRoom,
        sectionId: sectionId,
        homework: homework,
      ),
    );
  }

  void _showViewSheet(BuildContext context, Homework homework, String subjectName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ViewHomeworkSheet(
        homework: homework,
        subjectName: subjectName,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Homework'),
        content: const Text('Are you sure you want to delete this homework?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<HomeworkNotifier>().removeHomework(id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete homework')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Homework Card
// ─────────────────────────────────────────────────────────────────────────────

class _HomeworkCard extends StatelessWidget {
  final Homework homework;
  final String subjectName;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HomeworkCard({
    required this.homework,
    required this.subjectName,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final due =
        '${homework.dueDate.day.toString().padLeft(2, '0')}/${homework.dueDate.month.toString().padLeft(2, '0')}/${homework.dueDate.year}';
    final isPast = homework.dueDate.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    homework.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subjectName,
                    style: TextStyle(
                      color: const Color(0xFF7C3AED),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (homework.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      homework.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event_rounded,
                          size: 14,
                          color: isPast ? Colors.red[400] : Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Due: $due',
                        style: TextStyle(
                          fontSize: 11,
                          color: isPast ? Colors.red[400] : Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Delete
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              onSelected: (val) {
                if (val == 'view') {
                  onView();
                } else if (val == 'edit') {
                  onEdit();
                } else if (val == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('View'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Add Homework Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddHomeworkSheet extends StatefulWidget {
  final ClassRoom classRoom;
  final String? sectionId;
  final Homework? homework;

  const _AddHomeworkSheet({
    required this.classRoom,
    this.sectionId,
    this.homework,
  });

  @override
  State<_AddHomeworkSheet> createState() => _AddHomeworkSheetState();
}

class _AddHomeworkSheetState extends State<_AddHomeworkSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  String? _selectedSubjectId;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.homework?.title ?? '');
    _descController = TextEditingController(text: widget.homework?.description ?? '');
    _selectedSubjectId = widget.homework?.subjectId;
    _dueDate = widget.homework?.dueDate ?? DateTime.now().add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF7C3AED)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject')),
      );
      return;
    }

    final authNotifier = context.read<AuthNotifier>();
    final user = authNotifier.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No active user found.')),
      );
      return;
    }

    final homework = Homework(
      id: widget.homework?.id ?? '',
      teacherId: widget.homework?.teacherId ?? user.id,
      classId: widget.classRoom.id,
      sectionId: widget.homework?.sectionId ?? widget.sectionId ?? '',
      subjectId: _selectedSubjectId!,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      schoolId: user.schoolId ?? '',
      dueDate: _dueDate,
      createdAt: widget.homework?.createdAt ?? DateTime.now(),
    );

    final bool success;
    if (widget.homework == null) {
      success = await context.read<HomeworkNotifier>().submitHomework(homework);
    } else {
      success = await context.read<HomeworkNotifier>().updateHomework(homework);
    }
    
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.homework == null
                ? 'Homework assigned successfully!'
                : 'Homework updated successfully!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.homework == null
                ? 'Failed to assign homework.'
                : 'Failed to update homework.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context
        .watch<SubjectSetupNotifier>()
        .subjects
        .where((s) => s.classId == widget.classRoom.id)
        .toList();
    final dueLabel =
        '${_dueDate.day.toString().padLeft(2, '0')}/${_dueDate.month.toString().padLeft(2, '0')}/${_dueDate.year}';

    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.homework == null ? 'Add Homework' : 'Edit Homework',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 16),

                // Subject dropdown
                DropdownButtonFormField<String>(
                  decoration: _inputDeco('Subject'),
                  value: _selectedSubjectId,
                  items: subjects.isEmpty
                      ? [
                          const DropdownMenuItem(
                            value: '__none__',
                            child: Text('No subjects for this class'),
                          )
                        ]
                      : subjects
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ))
                          .toList(),
                  onChanged: subjects.isEmpty
                      ? null
                      : (val) => setState(() => _selectedSubjectId = val),
                ),
                const SizedBox(height: 12),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDeco('Homework Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: _inputDeco('Description (optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Due date
                GestureDetector(
                  onTap: _pickDueDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDeco('Due Date').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today_rounded),
                      ),
                      controller:
                          TextEditingController(text: dueLabel),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      widget.homework == null
                          ? 'Assign Homework'
                          : 'Update Homework',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F3FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// View Homework Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ViewHomeworkSheet extends StatelessWidget {
  final Homework homework;
  final String subjectName;

  const _ViewHomeworkSheet({
    required this.homework,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    final due =
        '${homework.dueDate.day.toString().padLeft(2, '0')}/${homework.dueDate.month.toString().padLeft(2, '0')}/${homework.dueDate.year}';
    final isPast = homework.dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Subject Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subjectName,
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            homework.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B4B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Info Row (Due Date)
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 18, color: isPast ? Colors.red : Colors.grey[600]),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due Date',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  Text(
                    due,
                    style: TextStyle(
                      color: isPast ? Colors.red : const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Description Section
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.1)),
            ),
            child: Text(
              homework.description.isNotEmpty
                  ? homework.description
                  : 'No description provided.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State widget
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: const Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
