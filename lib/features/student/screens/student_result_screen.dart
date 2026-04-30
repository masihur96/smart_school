import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';

import '../../../models/school_models.dart';
import '../providers/student_exam_provider.dart';
import 'student_exam_detail_screen.dart';

class StudentResultScreen extends StatefulWidget {
  final bool hideAppBar;
  const StudentResultScreen({super.key, this.hideAppBar = false});

  @override
  State<StudentResultScreen> createState() => _StudentResultScreenState();
}

class _StudentResultScreenState extends State<StudentResultScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<StudentExamNotifier>().fetchExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final examNotifier = context.watch<StudentExamNotifier>();
    final exams = examNotifier.exams;

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('Exams & Results'),
              backgroundColor: Colors.indigo[800],
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      context.read<StudentExamNotifier>().fetchExams(),
                ),
              ],
            ),
      body: examNotifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : examNotifier.error != null
          ? _buildErrorState(examNotifier.error!)
          : exams.isEmpty
          ? _buildEmptyState()
          : _buildExamsList(exams),
    );
  }

  Widget _buildExamsList(List<Exam> exams) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        return _buildExamCard(exam);
      },
    );
  }

  Widget _buildExamCard(Exam exam) {
    final bool isFinished =
        exam.endDate != null && exam.endDate!.isBefore(DateTime.now());

    return Card(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentExamDetailScreen(exam: exam),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isFinished ? Colors.grey : Colors.green)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isFinished ? 'Finished' : 'Ongoing / Upcoming',
                              style: TextStyle(
                                color: isFinished
                                    ? AppColors.white
                                    : Colors.green[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                if (exam.description != null &&
                    exam.description!.isNotEmpty) ...[
                  Text(
                    exam.description!,
                    style: TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.event,
                      'Start',
                      DateFormat(
                        'MMM dd',
                      ).format(exam.startDate ?? DateTime.now()),
                    ),
                    const SizedBox(width: 24),
                    _buildInfoItem(
                      Icons.event_available,
                      'End',
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(exam.endDate ?? DateTime.now()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.indigo.withOpacity(0.5)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10)),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No exams found.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for upcoming examinations.',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<StudentExamNotifier>().fetchExams(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
