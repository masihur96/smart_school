import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/student_exam_provider.dart';
import '../../../models/school_models.dart';

class StudentExamDetailScreen extends StatefulWidget {
  final Exam exam;
  const StudentExamDetailScreen({super.key, required this.exam});

  @override
  State<StudentExamDetailScreen> createState() => _StudentExamDetailScreenState();
}

class _StudentExamDetailScreenState extends State<StudentExamDetailScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.exam.name),
        backgroundColor: Colors.indigo[800],
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
        children: [
          _buildRoutineTab(),
          _buildSyllabusTab(),
          _buildResultsTab(),
        ],
      ),
    );
  }

  Widget _buildRoutineTab() {
    return Consumer<StudentExamNotifier>(
      builder: (context, p, child) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator());
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
        if (p.isLoading) return const Center(child: CircularProgressIndicator());
        final syllabusItems = p.syllabus.where((a) => a.syllabus != null && a.syllabus!.isNotEmpty).toList();
        if (syllabusItems.isEmpty) return _buildEmptyState('No syllabus detailed.');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: syllabusItems.length,
          itemBuilder: (context, index) {
            final assignment = syllabusItems[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.subjectName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
        if (p.isLoading) return const Center(child: CircularProgressIndicator());
        if (p.results.isEmpty) return _buildEmptyState('Results not published yet.');

        return _buildResultsList(p.results);
      },
    );
  }

  Widget _buildAssignmentCard(ExamAssignment a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.indigo[50], shape: BoxShape.circle),
          child: const Icon(Icons.assignment, color: Colors.indigo),
        ),
        title: Text(a.subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Examiner: ${a.examinerName}'),
            Text('Date: ${DateFormat('EEEE, MMM dd, yyyy').format(a.date)}'),
          ],
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
      child: Column(
        children: [
          _buildSummaryCard(totalObtained, totalMax, percentage),
          const SizedBox(height: 24),
          ...results.map((r) => _buildResultCard(r)).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double obtained, double max, double percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.indigo.shade500]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Total Performance', style: TextStyle(color: Colors.white70)),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Marks: ${obtained.toInt()} / ${max.toInt()}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Result result) {
    final percentage = result.totalMarks > 0 ? (result.marksObtained / result.totalMarks) : 0.0;
    final isPassed = result.marksObtained >= (result.totalMarks * 0.33);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.subject?.name ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('By ${result.teacher?.name ?? 'Teacher'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                Text(
                  '${result.marksObtained.toInt()}/${result.totalMarks.toInt()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPassed ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(isPassed ? Colors.green : Colors.indigo),
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
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
