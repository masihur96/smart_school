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
  ExamAssignment? _selectedAssignment;
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _totalMarksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.exam.assignments.isNotEmpty) {
      _selectedAssignment = widget.exam.assignments.first;
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
    final students = studentNotifier.students;

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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                Colors.blue,
              ),
              const Spacer(),
              _buildInfoItem(
                Icons.event_available_outlined,
                'End Date',
                DateFormat(
                  'MMM dd, yyyy',
                ).format(widget.exam.endDate ?? DateTime.now()),
                Colors.orange,
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assignments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${widget.exam.assignments.length} Total',
                style: TextStyle(
                  color: AppColors.primaryAdmin,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.exam.assignments.length,
            itemBuilder: (context, index) {
              final assignment = widget.exam.assignments[index];
              final isSelected = _selectedAssignment == assignment;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAssignment = assignment;
                  });
                  _fetchStudents();
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryAdmin : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? Colors.indigo.withOpacity(0.3)
                            : Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        assignment.subjectName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Class ${assignment.className}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white70
                              : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 10,
                            color: isSelected
                                ? Colors.white60
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd').format(assignment.date),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white60
                                  : Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
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
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                              TextInputType.numberWithOptions(decimal: true),
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
                      const SizedBox(height: 16),
                      _buildMarkField(
                        'Remarks',
                        _getRemarksController(student.userId),
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
            prefixIcon: Icon(icon, size: 18, color: Colors.indigo.shade300),
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
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(List<Student> students) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
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
