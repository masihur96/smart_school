import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/exam_provider.dart';
import '../../teacher/providers/result_provider.dart';
import '../../admin/providers/student_provider.dart';

class StudentResultScreen extends ConsumerStatefulWidget {
  const StudentResultScreen({super.key});

  @override
  ConsumerState<StudentResultScreen> createState() => _StudentResultScreenState();
}

class _StudentResultScreenState extends ConsumerState<StudentResultScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(resultsProvider.notifier).loadResultsForStudent(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final allExams = ref.watch(examsProvider);
    final results = ref.watch(resultsProvider);
    final students = ref.watch(studentsProvider);
    
    final student = students.where((s) => s.userId == user?.id).firstOrNull;
    if (student == null) return const Center(child: Text('Student data not found.'));

    final publishedExams = allExams.where((e) => 
      e.classId == student.classId && 
      e.isPublished
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Results'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: publishedExams.isEmpty
          ? const Center(child: Text('No published results found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: publishedExams.length,
              itemBuilder: (context, index) {
                final exam = publishedExams[index];
                final result = results.where((r) => r.examId == exam.id).firstOrNull;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        if (result != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Marks Obtained: ${result.marksObtained}', style: const TextStyle(fontSize: 16)),
                              Text('Total: ${result.totalMarks}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Status: ${result.remarks}', style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w600,
                            color: result.remarks == 'Pass' ? Colors.green : Colors.red,
                          )),
                        ] else
                          const Text('Result not yet available.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
