import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/exam_provider.dart';
import '../../teacher/providers/result_provider.dart';
import '../../admin/providers/student_provider.dart';

class StudentResultScreen extends ConsumerStatefulWidget {
  final bool hideAppBar;
  const StudentResultScreen({super.key, this.hideAppBar = false});

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
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('My Results'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: publishedExams.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(publishedExams, results),
                  const SizedBox(height: 24),
                  Text(
                    'Examination Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...publishedExams.map((exam) {
                    final result = results.where((r) => r.examId == exam.id).firstOrNull;
                    return _buildResultCard(exam, result);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No published results found.',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List exams, List results) {
    final relevantResults = results.where((r) => exams.any((e) => e.id == r.examId)).toList();
    if (relevantResults.isEmpty) return const SizedBox.shrink();

    final totalMarks = relevantResults.fold(0.0, (sum, r) => sum + r.totalMarks);
    final obtainedMarks = relevantResults.fold(0.0, (sum, r) => sum + r.marksObtained);
    final percentage = totalMarks == 0 ? 0.0 : (obtainedMarks / totalMarks) * 100;
    final passCount = relevantResults.where((r) => r.remarks == 'Pass').length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Performance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatInfo('Exams', exams.length.toString()),
              _buildStatInfo('Passed', passCount.toString()),
              _buildStatInfo('Total Marks', '${obtainedMarks.toInt()}/${totalMarks.toInt()}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatInfo(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildResultCard(exam, result) {
    final bool isPassed = result?.remarks == 'Pass';
    final percentage = (result != null && result.totalMarks > 0) 
        ? (result.marksObtained / result.totalMarks) 
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (result == null) ? Colors.grey.shade100 : (isPassed ? Colors.green.shade50 : Colors.red.shade50),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            result == null ? Icons.hourglass_empty : (isPassed ? Icons.check_circle : Icons.error),
            color: result == null ? Colors.grey : (isPassed ? Colors.green : Colors.red),
          ),
        ),
        title: Text(
          exam.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: result != null 
            ? Text('${result.marksObtained}/${result.totalMarks} Marks', style: TextStyle(color: Colors.grey[600]))
            : const Text('Awaiting results...', style: TextStyle(fontStyle: FontStyle.italic)),
        trailing: result != null ? _buildStatusChip(isPassed) : null,
        children: [
          if (result != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Performance Score', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('${(percentage * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(isPassed ? Colors.green : Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Remarks:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text(
                    result.remarks.isEmpty ? 'Excellent performance.' : result.remarks,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isPassed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPassed ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPassed ? 'Pass' : 'Fail',
        style: TextStyle(
          color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
