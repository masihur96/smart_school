import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';

import '../../../models/school_models.dart';
import '../providers/student_exam_provider.dart';

class StudentExamDetailScreen extends StatefulWidget {
  final Exam exam;
  const StudentExamDetailScreen({super.key, required this.exam});

  @override
  State<StudentExamDetailScreen> createState() =>
      _StudentExamDetailScreenState();
}

class _StudentExamDetailScreenState extends State<StudentExamDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    Future.microtask(() {
      final p = context.read<StudentExamNotifier>();
      p.fetchExamRoutine(widget.exam.id);
      p.fetchExamSyllabus(widget.exam.id);
      p.fetchExamResults(widget.exam.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.name),
        backgroundColor: AppColors.primaryStudent,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Routine', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Syllabus', icon: Icon(Icons.book)),
            Tab(text: 'Results', icon: Icon(Icons.assessment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRoutineTab(), _buildSyllabusTab(), _buildResultsTab()],
      ),
    );
  }

  Widget _buildRoutineTab() {
    return Consumer<StudentExamNotifier>(
      builder: (context, p, child) {
        if (p.isLoading)
          return const Center(child: CircularProgressIndicator());
        if (p.routine.isEmpty) return _buildEmptyState('No routine available.');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: p.routine.length,
          itemBuilder: (context, index) {
            final assignment = p.routine[index];
            return _buildAssignmentCard(assignment);
          },
        );
      },
    );
  }

  Widget _buildSyllabusTab() {
    return Consumer<StudentExamNotifier>(
      builder: (context, p, child) {
        if (p.isLoading)
          return const Center(child: CircularProgressIndicator());
        final syllabusItems = p.syllabus
            .where((a) => a.syllabus != null && a.syllabus!.isNotEmpty)
            .toList();
        if (syllabusItems.isEmpty)
          return _buildEmptyState('No syllabus detailed.');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: syllabusItems.length,
          itemBuilder: (context, index) {
            final assignment = syllabusItems[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.subjectName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    Text(
                      assignment.syllabus ?? 'No details.',
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResultsTab() {
    return Consumer<StudentExamNotifier>(
      builder: (context, p, child) {
        if (p.isLoading)
          return const Center(child: CircularProgressIndicator());
        if (p.results.isEmpty)
          return _buildEmptyState('Results not published yet.');

        return _buildResultsList(p.results);
      },
    );
  }

  Widget _buildAssignmentCard(ExamAssignment a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment, color: Colors.indigo),
          ),
          title: Text(
            a.subjectName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Examiner: ${a.examinerName}'),
              Text('Date: ${DateFormat('EEEE, MMM dd, yyyy').format(a.date)}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(List<Result> results) {
    double totalObtained = 0;
    double totalMax = 0;
    for (var r in results) {
      totalObtained += r.marksObtained;
      totalMax += r.totalMarks;
    }
    final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildSummaryCard(totalObtained, totalMax, percentage),
          const SizedBox(height: 24),
          ...results.map((r) => _buildResultCard(r)).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double obtained, double max, double percentage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 38),
        child: Column(
          children: [
            const Text(
              'Total Performance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Marks: ${obtained.toStringAsFixed(obtained.truncateToDouble() == obtained ? 0 : 2)} / ${max.toStringAsFixed(max.truncateToDouble() == max ? 0 : 2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Result result) {
    final percentage = result.totalMarks > 0
        ? (result.marksObtained / result.totalMarks)
        : 0.0;
    final isPassed = result.marksObtained >= (result.totalMarks * 0.33);
    final subjectName = result.subject?.name ?? 'Unknown Subject';
    final teacherName = result.teacher?.name ?? 'Unknown Teacher';

    final String initial = subjectName.isNotEmpty
        ? subjectName[0].toUpperCase()
        : '?';

    return Card(
      // margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primaryStudent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              teacherName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: (isPassed ? Colors.green : Colors.red).withOpacity(
                      0.08,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isPassed ? Colors.green : Colors.red).withOpacity(
                        0.2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        result.marksObtained.toStringAsFixed(
                          result.marksObtained.truncateToDouble() ==
                                  result.marksObtained
                              ? 0
                              : 2,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: isPassed ? null : Colors.red.shade700,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '/ ${result.totalMarks.toStringAsFixed(result.totalMarks.truncateToDouble() == result.totalMarks ? 0 : 2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPassed ? null : Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 10,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPassed
                            ? AppColors.primaryStudent
                            : Colors.red.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,

                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
