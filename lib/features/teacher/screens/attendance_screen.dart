import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/attendance_provider.dart';
import '../../admin/providers/student_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/entities/attendance.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  final bool hideAppBar;
  const AttendanceScreen({super.key, this.hideAppBar = false});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedClass;
  String? _selectedSection;
  Map<String, bool> _attendanceMap = {}; // studentId -> isPresent

  void _loadStudents() {
    if (_selectedClass != null && _selectedSection != null) {
      final students = ref.read(studentsProvider).where((s) => 
        s.classId == _selectedClass && s.sectionId == _selectedSection && s.isActive
      ).toList();
      
      final existingRecords = ref.read(attendanceProvider.notifier).getRecordsForDate(_selectedDate);
      
      setState(() {
        _attendanceMap = {
          for (var s in students) 
            s.userId: existingRecords.any((r) => r.studentId == s.userId && r.isPresent)
        };
      });
    }
  }

  void _save() {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    final records = _attendanceMap.entries.map((e) => AttendanceEntity(
      id: '${e.key}_${DateFormat('yyyyMMdd').format(_selectedDate)}',
      studentId: e.key,
      date: _selectedDate,
      isPresent: e.value,
      takenBy: currentUser.id,
    )).toList();

    ref.read(attendanceProvider.notifier).saveAttendance(records);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved successfully!')));
    if (!widget.hideAppBar) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider);
    final sections = ref.watch(sectionsProvider);
    final students = (_selectedClass != null && _selectedSection != null)
        ? ref.watch(studentsProvider).where((s) => 
            s.classId == _selectedClass && s.sectionId == _selectedSection && s.isActive
          ).toList()
        : [];

    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Take Attendance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Change'),
                      onPressed: () async {
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Class'),
                        value: _selectedClass,
                        items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) {
                          setState(() { _selectedClass = val; _selectedSection = null; });
                          _loadStudents();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Section'),
                        value: _selectedSection,
                        items: sections.where((s) => s.classId == _selectedClass).map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
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
          ),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text('No active students found.'))
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final isPresent = _attendanceMap[student.userId] ?? false;
                      return ListTile(
                        leading: CircleAvatar(child: Text(student.user?.name[0] ?? '?')),
                        title: Text(student.user?.name ?? 'Unknown'),
                        subtitle: Text('Roll: ${student.rollId}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(isPresent ? 'Present' : 'Absent', 
                                 style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Switch(
                              value: isPresent,
                              onChanged: (val) => setState(() => _attendanceMap[student.userId] = val),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: students.isEmpty ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Save Attendance', style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ),
    );
  }
}
