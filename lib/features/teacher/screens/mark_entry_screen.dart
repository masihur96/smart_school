import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Exam? _selectedExam;
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
    final exams = ref.watch(examsProvider).where((e) => e.teacherId == user?.id).toList();
    final students = ref.watch(studentsProvider);

    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Mark Entry'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<Exam>(
              value: _selectedExam,
              decoration: const InputDecoration(
                labelText: 'Select Exam',
                border: OutlineInputBorder(),
              ),
              items: exams.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedExam = val;
                  _markControllers.clear();
                });
                if (val != null) {
                  ref.read(resultsProvider.notifier).loadResultsForExam(val.id);
                }
              },
            ),
          ),
          if (_selectedExam != null) ...[
            Expanded(
              child: _buildStudentList(students.where((s) => s.classId == _selectedExam!.classId).toList()),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveMarks(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Save Marks'),
                ),
              ),
            ),
          ] else
            const Expanded(child: Center(child: Text('Please select an exam to enter marks.'))),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<dynamic> classStudents) {
    final existingResults = ref.watch(resultsProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: classStudents.length,
      itemBuilder: (context, index) {
        final student = classStudents[index];
        final existingResult = existingResults.where((r) => r.studentId == student.userId).firstOrNull;

        if (!_markControllers.containsKey(student.userId)) {
          _markControllers[student.userId] = TextEditingController(
            text: existingResult != null ? existingResult.marksObtained.toString() : '',
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(student.user.name),
            subtitle: Text('Roll: ${student.rollId}'),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                controller: _markControllers[student.userId],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'Marks',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveMarks() {
    if (_selectedExam == null) return;

    final results = _markControllers.entries.map((entry) {
      final marks = double.tryParse(entry.value.text) ?? 0.0;
      return Result(
        id: 'res_${_selectedExam!.id}_${entry.key}',
        examId: _selectedExam!.id,
        studentId: entry.key,
        marksObtained: marks,
        totalMarks: 100.0, // Hardcoded for now
        remarks: marks >= 40 ? 'Pass' : 'Fail',
      );
    }).toList();

    ref.read(resultsProvider.notifier).saveResults(results).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks saved successfully!')),
        );
      }
    });
  }
}
