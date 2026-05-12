import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';

import '../../../models/school_models.dart';
import '../../../models/student_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import '../providers/student_provider.dart';

class ExamViewScreen extends StatefulWidget {
  final Exam exam;
  const ExamViewScreen({super.key, required this.exam});

  @override
  State<ExamViewScreen> createState() => _ExamViewScreenState();
}

class _ExamViewScreenState extends State<ExamViewScreen> {
  late List<ExamAssignment> _sortedAssignments;
  String? _selectedClassId;
  ExamAssignment? _selectedAssignment;
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _totalMarksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    _sortedAssignments = List<ExamAssignment>.from(widget.exam.assignments)
      ..sort((a, b) => a.className.compareTo(b.className));
    if (_sortedAssignments.isNotEmpty) {
      _selectedAssignment = _sortedAssignments.first;
      _selectedClassId = _selectedAssignment!.classId;
      _fetchStudents();
    }
  }

  void _fetchStudents() {
    if (_selectedAssignment != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<StudentsNotifier>()
            .fetchStudentsBySection(classId: _selectedAssignment!.classId)
            .then((_) {
              if (mounted) {
                _populateExistingMarks();
              }
            });
      });
    }
  }

  void _populateExistingMarks() {
    if (_selectedAssignment == null) return;

    final students = context.read<StudentsNotifier>().students;
    if (students.isEmpty) return;

    setState(() {
      for (var student in students) {
        final existingResult = widget.exam.results.firstWhere(
          (r) =>
              r.studentId == student.userId &&
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
          _getMarksController(student.userId).text =
              existingResult.marksObtained ==
                  existingResult.marksObtained.toInt()
              ? existingResult.marksObtained.toInt().toString()
              : existingResult.marksObtained.toString();
          _getTotalMarksController(student.userId).text =
              existingResult.totalMarks == existingResult.totalMarks.toInt()
              ? existingResult.totalMarks.toInt().toString()
              : existingResult.totalMarks.toString();
          _getRemarksController(student.userId).text = existingResult.remarks;
        } else {
          _getMarksController(student.userId).clear();
          _getTotalMarksController(student.userId).text = '100';
          _getRemarksController(student.userId).clear();
        }
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _marksControllers.values) {
      controller.dispose();
    }
    for (var controller in _totalMarksControllers.values) {
      controller.dispose();
    }
    for (var controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
    final studentNotifier = context.watch<StudentsNotifier>();
    final students = List<Student>.from(studentNotifier.students)
      ..sort((a, b) {
        final aRoll = int.tryParse(a.rollId) ?? 0;
        final bRoll = int.tryParse(b.rollId) ?? 0;
        if (aRoll != 0 || bRoll != 0) {
          return aRoll.compareTo(bRoll);
        }
        return a.rollId.compareTo(b.rollId);
      });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExamSummary(),
                _buildAssignmentSelector(),
                _buildSectionHeader('Student List (${students.length})'),
              ],
            ),
          ),
          _buildStudentList(studentNotifier, students),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(students),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryAdmin,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.exam.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        background: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.assignment_outlined,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
      foregroundColor: Colors.white,
    );
  }

  Widget _buildExamSummary() {
    return Card(
      margin: const EdgeInsets.all(16),

      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildInfoItem(
                  Icons.calendar_month_outlined,
                  'Start Date',
                  DateFormat(
                    'MMM dd, yyyy',
                  ).format(widget.exam.startDate ?? DateTime.now()),
                ),
                const Spacer(),
                _buildInfoItem(
                  Icons.event_available_outlined,
                  'End Date',
                  DateFormat(
                    'MMM dd, yyyy',
                  ).format(widget.exam.endDate ?? DateTime.now()),
                ),
              ],
            ),
            if (widget.exam.description != null &&
                widget.exam.description!.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.exam.description!,
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignmentSelector() {
    final uniqueClasses = <String, String>{};
    for (var a in _sortedAssignments) {
      uniqueClasses[a.classId] = a.className;
    }

    final filteredAssignments = _sortedAssignments
        .where((a) => a.classId == _selectedClassId)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exam Selection',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${_sortedAssignments.length} Assignments',
                  style: TextStyle(
                    color: AppColors.primaryAdmin,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<String>(
                    label: 'Class',
                    value: _selectedClassId,
                    items: uniqueClasses.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedClassId = val;
                        final newFiltered = _sortedAssignments
                            .where((a) => a.classId == val)
                            .toList();
                        if (newFiltered.isNotEmpty) {
                          _selectedAssignment = newFiltered.first;
                        } else {
                          _selectedAssignment = null;
                        }
                      });
                      _fetchStudents();
                    },
                    icon: Icons.school_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownField<ExamAssignment>(
                    label: 'Subject',
                    value: _selectedAssignment,
                    items: filteredAssignments.map((a) {
                      return DropdownMenuItem(
                        value: a,
                        child: Text(
                          a.subjectName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedAssignment = val;
                      });
                      _fetchStudents();
                    },
                    icon: Icons.book_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade400,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildStudentList(
    StudentsNotifier studentNotifier,
    List<Student> students,
  ) {
    if (studentNotifier.isLoading) {
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
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No students found',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = students[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),

            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor:
                      Colors.transparent, // Removes top & bottom borders
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      student.user?.name[0] ?? 'S',
                      style: TextStyle(
                        color: AppColors.primaryAdmin,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    student.user?.name ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Roll: ${student.rollId}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: _getMarksController(student.userId).text.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_getMarksController(student.userId).text} / ${_getTotalMarksController(student.userId).text}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        children: [
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMarkField(
                                  'Marks Obtained',
                                  _getMarksController(student.userId),
                                  TextInputType.numberWithOptions(
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
                                  _getTotalMarksController(student.userId),
                                  TextInputType.number,
                                  Icons.summarize_outlined,
                                  onChanged: (val) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          // const SizedBox(height: 16),
                          // _buildMarkField(
                          //   'Remarks',
                          //   _getRemarksController(student.userId),
                          //   TextInputType.text,
                          //   Icons.note_alt_outlined,
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.indigo.shade400, width: 2),
            ),
            filled: true,
            // fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(List<Student> students) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 10),
        child: ElevatedButton(
          onPressed: _selectedAssignment == null || students.isEmpty
              ? null
              : () => _submitMarks(context, students),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAdmin,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: context.watch<ExamsNotifier>().isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: 8),
                    Text(
                      'Save All Marks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _submitMarks(BuildContext context, List<Student> students) async {
    if (_selectedAssignment == null) return;

    final authNotifier = context.read<AuthNotifier>();
    final schoolId = authNotifier.user?.schoolId;

    if (schoolId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('School ID not found')));
      return;
    }

    final List<Map<String, dynamic>> marksList = [];

    for (var student in students) {
      final marksStr = _getMarksController(student.userId).text.trim();
      if (marksStr.isEmpty) continue;

      final marksObtained = double.tryParse(marksStr);
      if (marksObtained == null) continue;

      marksList.add({
        'studentId': student.userId,
        'subjectId': _selectedAssignment!.subjectId,
        'marksObtained': marksObtained,
        'totalMarks':
            double.tryParse(_getTotalMarksController(student.userId).text) ??
            100.0,
        'remarks': _getRemarksController(student.userId).text,
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

    final success = await context.read<ExamsNotifier>().submitMarks(
      examId: widget.exam.id,
      teacherId: _selectedAssignment!.examinerId,
      schoolId: schoolId,
      marks: marksList,
    );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks submitted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit marks'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
