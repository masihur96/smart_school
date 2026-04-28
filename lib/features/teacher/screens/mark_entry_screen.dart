import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/result_provider.dart';

class MarkEntryScreen extends StatefulWidget {
  final bool hideAppBar;
  const MarkEntryScreen({super.key, this.hideAppBar = false});

  @override
  State<MarkEntryScreen> createState() => _MarkEntryScreenState();
}

class _MarkEntryScreenState extends State<MarkEntryScreen> {
  String? _selectedExamId;
  String? _selectedExamName;
  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedStudentId;
  String? _selectedStudentName;

  final Map<String, TextEditingController> _markControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResultsNotifier>().loadExams();
    });
  }

  @override
  void dispose() {
    for (final c in _markControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onExamChanged(String? examId, String? examName) {
    if (examId == null) return;
    setState(() {
      _selectedExamId = examId;
      _selectedExamName = examName;
      _selectedClassId = null;
      _selectedClassName = null;
      _selectedStudentId = null;
      _selectedStudentName = null;
      _markControllers.clear();
    });
    context.read<ResultsNotifier>().loadClasses(examId);
  }

  void _onClassChanged(String? classId, String? className) {
    if (classId == null || _selectedExamId == null) return;
    setState(() {
      _selectedClassId = classId;
      _selectedClassName = className;
      _selectedStudentId = null;
      _selectedStudentName = null;
      _markControllers.clear();
    });
    context.read<ResultsNotifier>().loadStudents(_selectedExamId!, classId);
  }

  void _onStudentChanged(String? studentId, String? studentName) {
    if (studentId == null ||
        _selectedExamId == null ||
        _selectedClassId == null) return;
    setState(() {
      _selectedStudentId = studentId;
      _selectedStudentName = studentName;
      _markControllers.clear();
    });
    context
        .read<ResultsNotifier>()
        .loadSubjects(_selectedExamId!, _selectedClassId!, studentId);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ResultsNotifier>();

    // Initialise controllers for subjects once loaded
    for (final sub in notifier.subjects) {
      if (!_markControllers.containsKey(sub.uuid)) {
        _markControllers[sub.uuid] = TextEditingController(
          text: sub.existingMark != null ? sub.existingMark.toString() : '',
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('Mark Entry System'),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectionCard(notifier),
                  const SizedBox(height: 28),
                  if (_selectedStudentId != null) ...[
                    _buildMarkEntrySection(notifier),
                    const SizedBox(height: 32),
                    if (notifier.subjects.isNotEmpty)
                      _buildSaveButton(notifier),
                    const SizedBox(height: 40),
                  ] else
                    _buildEmptySelectionState(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(ResultsNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ── Exam Dropdown ─────────────────────────────────────────────
            _buildDropdownField<String>(
              label: 'Examination',
              icon: Icons.assignment,
              value: _selectedExamId,
              loading: notifier.examsLoading,
              items: notifier.exams
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                final exam =
                    notifier.exams.where((e) => e.id == val).firstOrNull;
                _onExamChanged(val, exam?.name);
              },
            ),
            const SizedBox(height: 16),

            // ── Class Dropdown ─────────────────────────────────────────────
            _buildDropdownField<String>(
              label: 'Classroom',
              icon: Icons.meeting_room,
              value: _selectedClassId,
              loading: notifier.classesLoading,
              items: notifier.classes
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.uuid,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: _selectedExamId == null
                  ? null
                  : (val) {
                      final cls = notifier.classes
                          .where((c) => c.uuid == val)
                          .firstOrNull;
                      _onClassChanged(val, cls?.name);
                    },
            ),
            const SizedBox(height: 16),

            // ── Student Dropdown ───────────────────────────────────────────
            _buildDropdownField<String>(
              label: 'Student',
              icon: Icons.person_search,
              value: _selectedStudentId,
              loading: notifier.studentsLoading,
              items: notifier.students
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.rollNumber}. ${s.name}'),
                    ),
                  )
                  .toList(),
              onChanged: _selectedClassId == null
                  ? null
                  : (val) {
                      final student = notifier.students
                          .where((s) => s.id == val)
                          .firstOrNull;
                      _onStudentChanged(val, student?.name);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool loading = false,
  }) {
    return Stack(
      children: [
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.blue[700]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.blue.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items,
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          disabledHint: Text(
            'Select previous step first',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        if (loading)
          Positioned(
            right: 48,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMarkEntrySection(ResultsNotifier notifier) {
    if (notifier.subjectsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (notifier.subjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 60, color: Colors.amber[300]),
              const SizedBox(height: 16),
              const Text(
                'No subjects found for this student.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enter Marks for ${_selectedStudentName ?? "Student"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...notifier.subjects.map((sub) {
          final controller = _markControllers[sub.uuid];
          final marksText = controller?.text ?? '';
          final double? marks = double.tryParse(marksText);
          final bool isPass = marks != null && marks >= 40;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.book, color: Colors.blue[700]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Total: 100 Marks',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        hintText: '00',
                        suffixText:
                            marks != null ? (isPass ? 'P' : 'F') : null,
                        suffixStyle: TextStyle(
                          color: isPass ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSaveButton(ResultsNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: notifier.submitting ? null : () => _saveMarks(notifier),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: notifier.submitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Confirm & Save Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptySelectionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.manage_search, size: 100, color: Colors.grey[200]),
            const SizedBox(height: 20),
            Text(
              'Ready to Record Marks?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select exam, class and student above to proceed',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMarks(ResultsNotifier notifier) async {
    if (_selectedStudentId == null || _selectedExamId == null) return;

    final user = context.read<AuthNotifier>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not found. Please log in again.')),
      );
      return;
    }

    final marks = <Map<String, dynamic>>[];

    for (final sub in notifier.subjects) {
      final text = _markControllers[sub.uuid]?.text ?? '';
      if (text.isNotEmpty) {
        final marksObtained = double.tryParse(text) ?? 0.0;
        marks.add({
          'studentId': _selectedStudentId,
          'subjectId': sub.uuid,
          'marksObtained': marksObtained,
          'totalMarks': 100,
          'remarks': marksObtained >= 40 ? 'Pass' : 'Fail',
        });
      }
    }

    if (marks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter marks for at least one subject.')),
      );
      return;
    }

    try {
      await notifier.submitMarks(
        examId: _selectedExamId!,
        teacherId: user.id,
        schoolId: user.schoolId ?? '',
        marks: marks,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save marks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
