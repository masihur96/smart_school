import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/models/school_models.dart';

import '../../admin/providers/student_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/entities/attendance.dart';
import '../providers/attendance_provider.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final bool hideAppBar;
  const TeacherAttendanceScreen({super.key, this.hideAppBar = false});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedClass;
  String? _selectedSection;
  Map<String, AttendanceStatus> _attendanceMap = {}; // studentId -> status

  void _loadStudents() {
    if (_selectedClass != null && _selectedSection != null) {
      final students = context
          .read<StudentsNotifier>()
          .students
          .where(
            (s) =>
                s.classId == _selectedClass &&
                s.sectionId == _selectedSection &&
                s.isActive,
          )
          .toList();

      final existingRecords = context
          .read<AttendanceNotifier>()
          .getRecordsForDate(_selectedDate);

      setState(() {
        _attendanceMap = {
          for (var s in students)
            s.userId: existingRecords
                .firstWhere(
                  (r) => r.studentId == s.userId,
                  orElse: () => AttendanceEntity(
                    id: '',
                    studentId: '',
                    date: DateTime.now(),
                    status: AttendanceStatus.absent,
                    takenBy: '',
                  ),
                )
                .status,
        };
      });
    }
  }

  void _save() {
    final currentUser = context.read<AuthNotifier>().user;
    if (currentUser == null) return;

    final records = _attendanceMap.entries
        .map(
          (e) => AttendanceEntity(
            id: '${e.key}_${DateFormat('yyyyMMdd').format(_selectedDate)}',
            studentId: e.key,
            date: _selectedDate,
            status: e.value,
            takenBy: currentUser.id,
          ),
        )
        .toList();

    context.read<AttendanceNotifier>().saveAttendance(records);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance saved successfully!')),
    );
    if (!widget.hideAppBar) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;
    final studentsList = context.watch<StudentsNotifier>().students;

    final students = (_selectedClass != null && _selectedSection != null)
        ? studentsList
              .where(
                (s) =>
                    s.classId == _selectedClass &&
                    s.sectionId == _selectedSection &&
                    s.isActive,
              )
              .toList()
        : [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('Student Attendance'),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: Column(
        children: [
          _buildFilterSection(classes, sections),
          Expanded(
            child: students.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final status =
                          _attendanceMap[student.userId] ??
                          AttendanceStatus.absent;
                      return _buildStudentCard(student, status);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(students.isNotEmpty),
    );
  }

  Widget _buildFilterSection(List<ClassRoom> classes, List<Section> sections) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    _loadStudents();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Change Date',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeaderDropdown<String>(
                  label: 'Class',
                  value: _selectedClass,
                  items: classes
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedClass = val;
                      _selectedSection = null;
                    });
                    _loadStudents();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderDropdown<String>(
                  label: 'Section',
                  value: _selectedSection,
                  items: sections
                      .where((s) => s.classId == _selectedClass)
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedSection = val);
                    _loadStudents();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStudentCard(dynamic student, AttendanceStatus status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Text(
                    student.user?.name[0] ?? '?',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.user?.name ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Roll No: ${student.rollId}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusOption(
                  label: 'Present',
                  status: AttendanceStatus.present,
                  currentStatus: status,
                  activeColor: Colors.green,
                  icon: Icons.check_circle,
                  studentId: student.userId,
                ),
                _buildStatusOption(
                  label: 'Absent',
                  status: AttendanceStatus.absent,
                  currentStatus: status,
                  activeColor: Colors.red,
                  icon: Icons.cancel,
                  studentId: student.userId,
                ),
                _buildStatusOption(
                  label: 'Leave',
                  status: AttendanceStatus.leave,
                  currentStatus: status,
                  activeColor: Colors.orange,
                  icon: Icons.info,
                  studentId: student.userId,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required String label,
    required AttendanceStatus status,
    required AttendanceStatus currentStatus,
    required Color activeColor,
    required IconData icon,
    required String studentId,
  }) {
    final bool isActive = status == currentStatus;
    return InkWell(
      onTap: () => setState(() => _attendanceMap[studentId] = status),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? icon : Icons.circle_outlined,
              size: 16,
              color: isActive ? activeColor : Colors.grey[400],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'No active students found.',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Select class and section to load students',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool hasStudents) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: !hasStudents ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Submit Attendance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
