import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_result_provider.dart';
import '../../../models/school_models.dart';
import '../../../core/constants/api_path.dart';

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
      context.read<StudentResultNotifier>().fetchResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultNotifier = context.watch<StudentResultNotifier>();
    final results = resultNotifier.results;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('My Results'),
              backgroundColor: Colors.indigo[800],
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<StudentResultNotifier>().fetchResults(),
                ),
              ],
            ),
      body: resultNotifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : resultNotifier.error != null
              ? _buildErrorState(resultNotifier.error!)
              : results.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsList(results),
    );
  }

  Widget _buildResultsList(List<Result> results) {
    // Group results by exam ID or name
    final Map<String, List<Result>> groupedResults = {};
    for (var r in results) {
      final examName = r.exam?.name ?? 'Other Examinations';
      if (!groupedResults.containsKey(examName)) {
        groupedResults[examName] = [];
      }
      groupedResults[examName]!.add(r);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryOverview(results),
          const SizedBox(height: 24),
          ...groupedResults.entries.map((entry) {
            return _buildExamSection(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryOverview(List<Result> results) {
    double totalObtained = 0;
    double totalMax = 0;
    for (var r in results) {
      totalObtained += r.marksObtained;
      totalMax += r.totalMarks;
    }
    final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
    final gpa = _calculateGPA(percentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
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
                  const Text(
                    'Academic Performance',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'GPA',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      gpa.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleStat('Subjects', results.length.toString()),
              _buildSimpleStat('Total Marks', '${totalObtained.toInt()}/${totalMax.toInt()}'),
              _buildSimpleStat('Grade', _calculateGrade(percentage)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildExamSection(String examName, List<Result> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(
            examName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildResultCard(result);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResultCard(Result result) {
    final percentage = result.totalMarks > 0 ? (result.marksObtained / result.totalMarks) : 0.0;
    final isPassed = result.marksObtained >= (result.totalMarks * 0.33); // Example pass criteria

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isPassed ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPassed ? Icons.book : Icons.warning_amber_rounded,
                    color: isPassed ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.subject?.name ?? 'Unknown Subject',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'By ${result.teacher?.name ?? 'Assigned Teacher'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${result.marksObtained.toInt()}/${result.totalMarks.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isPassed ? 'Passed' : 'Failed',
                      style: TextStyle(
                        color: isPassed ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPassed ? Colors.green : Colors.red,
                ),
              ),
            ),
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
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No results published yet.',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
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
          TextButton(
            onPressed: () => context.read<StudentResultNotifier>().fetchResults(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  double _calculateGPA(double percentage) {
    if (percentage >= 80) return 5.0;
    if (percentage >= 70) return 4.0;
    if (percentage >= 60) return 3.5;
    if (percentage >= 50) return 3.0;
    if (percentage >= 40) return 2.0;
    if (percentage >= 33) return 1.0;
    return 0.0;
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 80) return 'A+';
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'A-';
    if (percentage >= 50) return 'B';
    if (percentage >= 40) return 'C';
    if (percentage >= 33) return 'D';
    return 'F';
  }
}

