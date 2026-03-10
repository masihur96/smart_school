import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/models/student_model.dart';
import '../../../models/school_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/exam_provider.dart';
import '../../admin/providers/student_provider.dart';
import '../providers/result_provider.dart';

class MarkEntryScreen extends ConsumerStatefulWidget {
  final bool hideAppBar;
  const MarkEntryScreen({super.key, this.hideAppBar = false});

  @override
  ConsumerState<MarkEntryScreen> createState() => _MarkEntryScreenState();
}

class _MarkEntryScreenState extends ConsumerState<MarkEntryScreen> {
  String? _selectedExamName;
  String? _selectedClassId;
  String? _selectedStudentId;
  final Map<String, TextEditingController> _markControllers = {};

  @override
  void dispose() {
    for (var controller in _markControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final allExams = ref.watch(examsProvider).where((e) => e.teacherId == user?.id).toList();
    final allStudents = ref.watch(studentsProvider);
    final classes = ref.watch(classSetupProvider);
    final subjects = ref.watch(subjectSetupProvider);

    final uniqueExamNames = allExams.map((e) => e.name).toSet().toList();
    
    final classesForSelectedExam = _selectedExamName == null 
        ? <ClassRoom>[] 
        : classes.where((c) => allExams.any((e) => e.name == _selectedExamName && e.classId == c.id)).toList();

    final studentsForSelectedClass = _selectedClassId == null
        ? <Student>[]
        : allStudents.where((s) => s.classId == _selectedClassId).toList();

    final results = ref.watch(resultsProvider);

    final examsToEnterMarks = (_selectedExamName != null && _selectedClassId != null && _selectedStudentId != null)
        ? allExams.where((e) => e.name == _selectedExamName && e.classId == _selectedClassId).toList()
        : <Exam>[];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Mark Entry System'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {}, // Help info
          ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectionCard(
                    uniqueExamNames, 
                    classesForSelectedExam, 
                    studentsForSelectedClass
                  ),
                  const SizedBox(height: 28),
                  if (_selectedStudentId != null) ...[
                    _buildMarkEntrySection(examsToEnterMarks, subjects, results),
                    const SizedBox(height: 32),
                    if (examsToEnterMarks.isNotEmpty)
                      _buildSaveButton(examsToEnterMarks),
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



  Widget _buildSelectionCard(
    List<String> uniqueExamNames,
    List<ClassRoom> classesForSelectedExam,
    List<Student> studentsForSelectedClass,
  ) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildDropdownField<String>(
              label: 'Examination',
              icon: Icons.assignment,
              value: _selectedExamName,
              items: uniqueExamNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedExamName = val;
                  _selectedClassId = null;
                  _selectedStudentId = null;
                  _markControllers.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownField<String>(
              label: 'Classroom',
              icon: Icons.meeting_room,
              value: _selectedClassId,
              items: classesForSelectedExam.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: _selectedExamName == null ? null : (val) {
                setState(() {
                  _selectedClassId = val;
                  _selectedStudentId = null;
                  _markControllers.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownField<String>(
              label: 'Student',
              icon: Icons.person_search,
              value: _selectedStudentId,
              items: studentsForSelectedClass.map((s) => DropdownMenuItem(value: s.userId, child: Text(s.user?.name ?? 'Unknown'))).toList(),
              onChanged: _selectedClassId == null ? null : (val) {
                setState(() {
                  _selectedStudentId = val;
                  _markControllers.clear();
                });
                if (val != null) {
                  ref.read(resultsProvider.notifier).loadResultsForStudent(val);
                }
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
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.blue.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items,
      onChanged: onChanged,
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      disabledHint: Text('Select previous step first', style: TextStyle(color: Colors.grey[400])),
    );
  }

  Widget _buildMarkEntrySection(List<Exam> exams, List<Subject> subjects, List<Result> results) {
    if (exams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.warning_amber_rounded, size: 60, color: Colors.amber[300]),
              const SizedBox(height: 16),
              const Text('No exams found for this selection.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Enter Subject Marks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...exams.map((exam) {
          final subject = subjects.firstWhere((s) => s.id == exam.subjectId, orElse: () => Subject(id: '', name: 'Unknown'));
          
          if (!_markControllers.containsKey(exam.id)) {
            final existingResult = results.where((r) => r.examId == exam.id && r.studentId == _selectedStudentId).firstOrNull;
            _markControllers[exam.id] = TextEditingController(
              text: existingResult != null ? existingResult.marksObtained.toString() : '',
            );
          }

          final marksText = _markControllers[exam.id]?.text ?? '';
          final double? marks = double.tryParse(marksText);
          final bool isPass = marks != null && marks >= 40;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
            ),
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
                        Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Total: 100 Marks', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _markControllers[exam.id],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (val) => setState(() {}),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: '00',
                        suffixText: marks != null ? (isPass ? 'P' : 'F') : null,
                        suffixStyle: TextStyle(
                          color: isPass ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildSaveButton(List<Exam> exams) {
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
        onPressed: () => _saveMarks(exams),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Confirm & Save Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'Select exam and student above to proceed',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMarks(List<Exam> exams) {
    if (_selectedStudentId == null) return;

    final results = <Result>[];
    for (var exam in exams) {
      final marksText = _markControllers[exam.id]?.text ?? '';
      if (marksText.isNotEmpty) {
        final marks = double.tryParse(marksText) ?? 0.0;
        results.add(Result(
          id: 'res_${exam.id}_$_selectedStudentId',
          examId: exam.id,
          studentId: _selectedStudentId!,
          marksObtained: marks,
          totalMarks: 100.0,
          remarks: marks >= 40 ? 'Pass' : 'Fail',
        ));
      }
    }

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter marks for at least one subject.')),
      );
      return;
    }

    ref.read(resultsProvider.notifier).saveResults(results).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks saved successfully!')),
        );
      }
    });
  }
}
