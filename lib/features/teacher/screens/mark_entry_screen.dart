import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/models/school_models.dart';

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
  Exam? _selectedExam;
  String? _selectedClassId;
  String? _selectedSectionId;
  ExamAssignment? _selectedAssignment;

  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _totalMarksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResultsNotifier>().loadExams();
      context.read<SectionSetupNotifier>().fetchSections();
    });
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var c in _marksControllers.values) c.dispose();
    for (var c in _totalMarksControllers.values) c.dispose();
    for (var c in _remarksControllers.values) c.dispose();
    _marksControllers.clear();
    _totalMarksControllers.clear();
    _remarksControllers.clear();
  }

  void _onExamChanged(Exam? exam) {
    setState(() {
      _selectedExam = exam;
      _selectedExamId = exam?.id;
      _selectedClassId = null;
      _selectedSectionId = null;
      _selectedAssignment = null;
      _disposeControllers();
    });
  }

  void _onClassChanged(String? classId) {
    setState(() {
      _selectedClassId = classId;
      _selectedSectionId = null;
      _selectedAssignment = null;
      _disposeControllers();
    });
  }

  void _onSectionChanged(String? sectionId) {
    setState(() {
      _selectedSectionId = sectionId;
      _selectedAssignment = null;
      _disposeControllers();
    });
    _fetchStudents();
  }

  void _onAssignmentChanged(ExamAssignment? assignment) {
    setState(() {
      _selectedAssignment = assignment;
      _disposeControllers();
    });
    _fetchStudents();
  }

  void _fetchStudents() {
    if (_selectedClassId != null) {
      context
          .read<ResultsNotifier>()
          .loadStudents(
            _selectedExam?.id ?? '',
            _selectedClassId!,
            sectionId: _selectedSectionId,
          )
          .then((_) {
            if (mounted) {
              _populateExistingMarks();
            }
          });
    }
  }

  void _populateExistingMarks() {
    if (_selectedExam == null || _selectedAssignment == null) return;

    final students = context.read<ResultsNotifier>().students;
    if (students.isEmpty) return;

    setState(() {
      for (var student in students) {
        final existingResult = _selectedExam!.results.firstWhere(
          (r) =>
              r.studentId == student.id &&
              r.subjectId == _selectedAssignment!.subjectId,
          orElse: () => Result(
            id: '',
            examId: '',
            studentId: '',
            marksObtained: -1,
            totalMarks: 100,
            remarks: '',
          ),
        );

        if (existingResult.marksObtained != -1) {
          _getMarksController(student.id).text =
              existingResult.marksObtained ==
                  existingResult.marksObtained.toInt()
              ? existingResult.marksObtained.toInt().toString()
              : existingResult.marksObtained.toString();
          _getTotalMarksController(student.id).text =
              existingResult.totalMarks == existingResult.totalMarks.toInt()
              ? existingResult.totalMarks.toInt().toString()
              : existingResult.totalMarks.toString();
          _getRemarksController(student.id).text = existingResult.remarks;
        } else {
          _getMarksController(student.id).clear();
          _getTotalMarksController(student.id).text = '100';
          _getRemarksController(student.id).clear();
        }
      }
    });
  }

  TextEditingController _getMarksController(String studentId) {
    return _marksControllers.putIfAbsent(
      studentId,
      () => TextEditingController(),
    );
  }

  TextEditingController _getTotalMarksController(String studentId) {
    return _totalMarksControllers.putIfAbsent(
      studentId,
      () => TextEditingController(text: '100'),
    );
  }

  TextEditingController _getRemarksController(String studentId) {
    return _remarksControllers.putIfAbsent(
      studentId,
      () => TextEditingController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ResultsNotifier>();
    final students = notifier.students;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildFilterCard(notifier),
                if (_selectedAssignment != null)
                  _buildSectionHeader('Students (${students.length})'),
              ],
            ),
          ),
          if (_selectedAssignment != null)
            _buildStudentList(notifier, students)
          else
            _buildEmptyState(),
        ],
      ),
      bottomNavigationBar: _selectedAssignment != null
          ? _buildBottomBar(students)
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryTeacher,
      foregroundColor: Colors.white,
      // flexibleSpace: FlexibleSpaceBar(
      //   title: const Text(
      //     'Mark Entry System',
      //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      //   ),
      //   background: Stack(
      //     children: [
      //       Positioned(
      //         right: -20,
      //         top: -20,
      //         child: Icon(
      //           Icons.edit_document,
      //           size: 150,
      //           color: Colors.white.withValues(alpha: 0.1),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _buildFilterCard(ResultsNotifier notifier) {
    final uniqueClasses = <String, String>{};
    if (_selectedExam != null) {
      for (var a in _selectedExam!.assignments) {
        uniqueClasses[a.classId] = a.className;
      }
    }

    final sections = context.watch<SectionSetupNotifier>().sections;
    final filteredSections = sections
        .where((s) => s.classId == _selectedClassId)
        .toList();

    final filteredAssignments =
        _selectedExam?.assignments
            .where((a) => a.classId == _selectedClassId)
            .toList() ??
        [];

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDropdownField<String>(
              label: 'Examination',
              icon: Icons.assignment_outlined,
              value: _selectedExamId,
              loading: notifier.examsLoading,
              items: notifier.exams
                  .map(
                    (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                  )
                  .toList(),
              onChanged: (id) {
                final exam = notifier.exams.firstWhere((e) => e.id == id);
                _onExamChanged(exam);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<String>(
                    label: 'Class',
                    icon: Icons.school_outlined,
                    value: _selectedClassId,
                    enabled: _selectedExam != null,
                    items: uniqueClasses.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: _onClassChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownField<String>(
                    label: 'Section',
                    icon: Icons.grid_view_outlined,
                    value: _selectedSectionId,
                    enabled: _selectedClassId != null,
                    items: filteredSections
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: _onSectionChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdownField<ExamAssignment>(
              label: 'Subject Assignment',
              icon: Icons.book_outlined,
              value: _selectedAssignment,
              enabled: _selectedClassId != null,
              items: filteredAssignments
                  .map(
                    (a) =>
                        DropdownMenuItem(value: a, child: Text(a.subjectName)),
                  )
                  .toList(),
              onChanged: _onAssignmentChanged,
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
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            filled: true,
            fillColor: enabled
                ? Colors.blue.withValues(alpha: 0.05)
                : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items,
          onChanged: enabled ? onChanged : null,
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.keyboard_arrow_down),
          disabledHint: Text(
            enabled ? 'Select' : 'Select previous first',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (_selectedAssignment != null)
            Text(
              _selectedAssignment!.subjectName,
              style: TextStyle(
                color: AppColors.primaryTeacher,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentList(
    ResultsNotifier notifier,
    List<TeacherAssignmentStudent> students,
  ) {
    if (notifier.studentsLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (students.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text('No students found for this selection'),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = students[index];
          final marksStr = _getMarksController(student.id).text;
          final marks = double.tryParse(marksStr);
          final isEntered = marksStr.isNotEmpty;
          final bool isPass = marks != null && marks >= 40;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryTeacher.withValues(
                  alpha: 0.1,
                ),
                child: Text(
                  student.name[0],
                  style: const TextStyle(
                    color: AppColors.primaryTeacher,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Roll: ${student.rollNumber}'),
              trailing: isEntered
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPass ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${marks.toString()} / ${_getTotalMarksController(student.id).text}',
                        style: TextStyle(
                          color: isPass ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : const Icon(Icons.add_circle_outline, color: Colors.grey),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMarkField(
                              'Marks Obtained',
                              _getMarksController(student.id),
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              Icons.grade_outlined,
                              onChanged: (val) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMarkField(
                              'Total Marks',
                              _getTotalMarksController(student.id),
                              TextInputType.number,
                              Icons.summarize_outlined,
                              onChanged: (val) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildMarkField(
                        'Remarks',
                        _getRemarksController(student.id),
                        TextInputType.text,
                        Icons.note_alt_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }, childCount: students.length),
      ),
    );
  }

  Widget _buildMarkField(
    String label,
    TextEditingController controller,
    TextInputType type,
    IconData icon, {
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 18),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(List<TeacherAssignmentStudent> students) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: context.watch<ResultsNotifier>().submitting
              ? null
              : () => _saveAllMarks(students),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeacher,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: context.watch<ResultsNotifier>().submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined),
                    SizedBox(width: 8),
                    Text(
                      'Save All Results',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search, size: 80, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              'Select Filters to Start',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose exam and classroom to enter marks',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAllMarks(List<TeacherAssignmentStudent> students) async {
    if (_selectedExam == null || _selectedAssignment == null) return;

    final authNotifier = context.read<AuthNotifier>();
    final user = authNotifier.user;
    if (user == null) return;

    final List<Map<String, dynamic>> marksList = [];

    for (var student in students) {
      final marksStr = _getMarksController(student.id).text.trim();
      if (marksStr.isEmpty) continue;

      final marksObtained = double.tryParse(marksStr);
      if (marksObtained == null) continue;

      marksList.add({
        'studentId': student.id,
        'subjectId': _selectedAssignment!.subjectId,
        'marksObtained': marksObtained,
        'totalMarks':
            double.tryParse(_getTotalMarksController(student.id).text) ?? 100.0,
        'remarks': _getRemarksController(student.id).text,
      });
    }

    if (marksList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter marks for at least one student'),
        ),
      );
      return;
    }

    try {
      await context.read<ResultsNotifier>().submitMarks(
        examId: _selectedExam!.id,
        teacherId: user.id,
        schoolId: user.schoolId ?? '',
        marks: marksList,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save marks: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
