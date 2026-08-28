import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/school_models.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/result_provider.dart';
import '../providers/teacher_dashboard_provider.dart';
import '../../../services/notification_service.dart';

class MarkEntryScreen extends StatefulWidget {
  final bool hideAppBar;
  final String initialExamId;
  final String initialClassId;
  final String initialSectionId;
  final String initialSubjectId;
  const MarkEntryScreen({
    super.key,
    this.hideAppBar = false,
   required this.initialExamId,
   required this.initialClassId,
   required this.initialSectionId,
   required this.initialSubjectId,
  });

  @override
  State<MarkEntryScreen> createState() => _MarkEntryScreenState();
}

class _MarkEntryScreenState extends State<MarkEntryScreen> {
  String? _selectedExamId;
  Exam? _selectedExam;
  String? _selectedClassId;
  String? _selectedSectionId;
  Subject? _selectedSubject;

  // All students in this class fetched from server
  List<TeacherAssignmentStudent>? _allClassStudents;

  // Currently displayed students
  List<TeacherAssignmentStudent> _displayStudents = [];

  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _totalMarksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionNotifier = context.read<SectionSetupNotifier>();
      if (sectionNotifier.sections.isEmpty) {
        sectionNotifier.fetchSections();
      }

      _fetchStudents();
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

  void _fetchStudents() {
    final resultsNotifier = context.read<ResultsNotifier>();

    final exam = resultsNotifier.exams.firstWhere(
      (e) => e.id == widget.initialExamId,
      orElse: () => Exam(id: widget.initialExamId, name: ''),
    );

    String subjectName = 'Subject';
    try {
      final assignment = exam.assignments.firstWhere(
        (a) => a.subjectId == widget.initialSubjectId,
      );
      subjectName = assignment.subjectName;
    } catch (_) {}

    setState(() {
      _selectedExam = exam;
      _selectedExamId = exam.id;
      _selectedClassId = widget.initialClassId;
      _selectedSectionId = widget.initialSectionId.isNotEmpty
          ? widget.initialSectionId
          : null;
      _selectedSubject = Subject(id: widget.initialSubjectId, name: subjectName);
    });

    _loadStudentsForSection(_selectedSectionId);
  }

  void _filterAndDisplayStudents(String? sectionId) {
    if (_allClassStudents == null) return;
    
    setState(() {
      if (sectionId != null && sectionId.isNotEmpty) {
        _displayStudents = _allClassStudents!
            .where((s) => s.sectionId == sectionId)
            .toList();
      } else {
        _displayStudents = List.from(_allClassStudents!);
      }
    });
    _populateExistingMarks();
  }

  void _loadStudentsForSection(String? sectionId) {
    if (_allClassStudents != null) {
      _filterAndDisplayStudents(sectionId);
      return;
    }

    final resultsNotifier = context.read<ResultsNotifier>();
    if (_selectedClassId == null) return;

    // Fetch all students for the class once
    resultsNotifier
        .loadStudents(
          _selectedExam?.id ?? '',
          _selectedClassId!,
          sectionId: null, // Ensure we fetch all
        )
        .then((_) {
          if (mounted) {
            _allClassStudents = List<TeacherAssignmentStudent>.from(
              resultsNotifier.students,
            );
            
            _filterAndDisplayStudents(sectionId);
          }
        });
  }

  void _populateExistingMarks() {
    if (_selectedExam == null || _selectedSubject == null) return;

    final students = _displayStudents;
    if (students.isEmpty) return;

    setState(() {
      for (var student in students) {
        final existingResult = _selectedExam!.results.firstWhere(
          (r) =>
              r.studentId == student.id && r.subjectId == _selectedSubject!.id,
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
    final students = _displayStudents;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (_selectedClassId != null) _buildSectionFilterCard(),
                if (_selectedSubject != null)
                  _buildSectionHeader('Students (${students.length})'),
              ],
            ),
          ),
          if (_selectedSubject != null)
            _buildStudentList(notifier, students)
          else
            _buildEmptyState(),
        ],
      ),
      bottomNavigationBar: _selectedSubject != null
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
      title: const Text(
        'Mark Entry System',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildSectionFilterCard() {
    final sections = context.watch<SectionSetupNotifier>().sections;
    final filteredSections = sections
        .where((s) => s.classId == _selectedClassId)
        .toList();

    final hasValidSection = filteredSections.any((s) => s.id == _selectedSectionId);
    final displayValue = hasValidSection ? _selectedSectionId : null;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.grid_view_outlined, color: Colors.grey),
            const SizedBox(width: 16),
            const Text(
              'Section:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: displayValue,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                hint: const Text('Select Section'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Sections'),
                  ),
                  ...filteredSections.map(
                    (s) => DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedSectionId = val;
                  });
                  _loadStudentsForSection(val);
                },
              ),
            ),
          ],
        ),
      ),
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
          if (_selectedSubject != null)
            Text(
              _selectedSubject!.name,
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
              Text(AppLocalizations.of(context)!.noStudentsForSelection),
            ],
          ),
        ),
      );
    }

    final sortedStudents = List<TeacherAssignmentStudent>.from(students)
      ..sort((a, b) {
        final numA = int.tryParse(a.rollNumber);
        final numB = int.tryParse(b.rollNumber);
        if (numA != null && numB != null) {
          return numA.compareTo(numB);
        }
        return a.rollNumber.compareTo(b.rollNumber);
      });

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = sortedStudents[index];
          final marksStr = _getMarksController(student.id).text;
          final marks = double.tryParse(marksStr);
          final isEntered = marksStr.isNotEmpty;
          final bool isPass = marks != null && marks >= 40;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor:
                    Colors.transparent, // Removes top & bottom borders
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
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
                subtitle: Text(AppLocalizations.of(context)!.rollNumber(student.rollNumber.toString())),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: sortedStudents.length),
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
            // filled: true,
            // fillColor: Colors.grey[50],
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
    return const SliverFillRemaining(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _saveAllMarks(List<TeacherAssignmentStudent> students) async {
    if (_selectedExam == null || _selectedSubject == null) return;

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
        'subjectId': _selectedSubject!.id,
        'marksObtained': marksObtained,
        'totalMarks':
            double.tryParse(_getTotalMarksController(student.id).text) ?? 100.0,
        'remarks': _getRemarksController(student.id).text,
      });
    }

    if (marksList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.marksEnteredRequired),
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
        // Notify admin only
        final adminInfo = context
            .read<TeacherDashboardProvider>()
            .dashboardData
            ?.schoolAdminInfo;
        if (adminInfo != null && adminInfo.id.isNotEmpty) {
          NotificationService().sendBulkNotification(
            receiverUuids: [adminInfo.id],
            title: '📊 Marks Submitted',
            message:
                'Marks for "${_selectedExam!.name}" – ${_selectedSubject!.name} '
                '(${_marksControllers.length} student(s)) have been saved by ${user.name}.',
            additionalData: {
              'type': 'mark_entry',
              'examId': _selectedExam!.id,
              'subjectId': _selectedSubject!.id,
            },
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.marksSavedSuccessfully),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSaveMarks(e.toString())),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
