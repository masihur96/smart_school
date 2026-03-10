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
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Mark Entry'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown<String>(
              label: 'Select Exam Name',
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
            _buildDropdown<String>(
              label: 'Select Class',
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
            _buildDropdown<String>(
              label: 'Select Student',
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
            const SizedBox(height: 24),
            if (_selectedStudentId != null && examsToEnterMarks.isNotEmpty) ...[
              const Text(
                'Enter Marks for Subjects',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...examsToEnterMarks.map((exam) {
                final subject = subjects.firstWhere((s) => s.id == exam.subjectId, orElse: () => Subject(id: '', name: 'Unknown'));
                
                if (!_markControllers.containsKey(exam.id)) {
                  final existingResult = results.where((r) => r.examId == exam.id && r.studentId == _selectedStudentId).firstOrNull;
                  _markControllers[exam.id] = TextEditingController(
                    text: existingResult != null ? existingResult.marksObtained.toString() : '',
                  );
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('Exam: ${exam.name}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _markControllers[exam.id],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Marks',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveMarks(examsToEnterMarks),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save All Marks', style: TextStyle(fontSize: 16)),
                ),
              ),
            ] else if (_selectedStudentId != null)
              const Center(child: Text('No exams found for the selected criteria.'))
            else
              const Center(child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('Please select Exam, Class, and Student to enter marks.'),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: items.isEmpty && onChanged != null,
        fillColor: Colors.grey[100],
      ),
      items: items,
      onChanged: onChanged,
      disabledHint: Text('Select previous option first'),
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
