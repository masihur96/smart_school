import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/school_models.dart';

import '../providers/teacher_dashboard_provider.dart';
import 'teacher_exam_details_screen.dart';

class TeacherExamScreen extends StatefulWidget {
  final bool hideAppBar;
  const TeacherExamScreen({super.key, this.hideAppBar = false});

  @override
  State<TeacherExamScreen> createState() => _TeacherExamScreenState();
}

class _TeacherExamScreenState extends State<TeacherExamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TeacherDashboardProvider>();

      if (provider.exams.isEmpty) {
        provider.fetchExams();
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<TeacherDashboardProvider>().fetchExams();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<TeacherDashboardProvider>();
    final exams = provider.exams;

    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: Text(l10n?.exams ?? ""),
        backgroundColor: AppColors.primaryTeacher,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(onPressed: _refresh, child: Text(l10n?.viewAll ?? "",style: TextStyle(color: Colors.white),)),
         ],
      ),
      body: provider.isLoading && exams.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: exams.isEmpty
                  ? _buildEmptyState(l10n!)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: exams.length,
                      itemBuilder: (context, index) {
                        return _buildExamCard(context, exams[index], l10n!);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No exams found',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(
    BuildContext context,
    Exam exam,
    AppLocalizations l10n,
  ) {

    final dateRange = exam.startDate != null && exam.endDate != null
        ? '${DateFormat('MMM dd').format(exam.startDate!)} - ${DateFormat('MMM dd').format(exam.endDate!)}'
        : (exam.startDate != null
              ? DateFormat('MMM dd').format(exam.startDate!)
              : 'N/A');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherExamDetailsScreen(exam: exam),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exam.name,
                          style: const TextStyle(

                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: exam.isPublished
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          exam.isPublished ? 'Published' : 'Draft',
                          style:  TextStyle(
                            color: exam.isPublished
                                ? Colors.green
                                : Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (exam.description != null && exam.description!.isNotEmpty)
                    Text(
                      exam.description!,
                      style: TextStyle(

                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildInfoBadge(
                        Icons.calendar_today,
                        dateRange,
                        Colors.blue.shade50,
                        Colors.blue.shade900,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoBadge(
                        Icons.menu_book,
                        '${exam.assignments.length} Routines',
                        Colors.amber.shade50,
                        Colors.amber.shade900,
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
  }

  Widget _buildInfoBadge(
    IconData icon,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Card(
      margin: EdgeInsets.zero,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryTeacher),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primaryTeacher.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class TeacherExamRoutineView extends StatelessWidget {
  final Exam exam;
  final ScrollController scrollController;

  const TeacherExamRoutineView({
    super.key,
    required this.exam,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (exam.assignments.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noRoutinesAssigned));
    }

    final grouped = <String, List<ExamAssignment>>{};
    for (var a in exam.assignments) {
      grouped.putIfAbsent(a.className, () => []).add(a);
    }
    final classNames = grouped.keys.toList();
    classNames.sort();

    return DefaultTabController(
      length: classNames.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeacher.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.event_note,
                    color: AppColors.primaryTeacher,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXAM SCHEDULES',
                        style: TextStyle(
                          color: AppColors.primaryTeacher.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exam.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primaryTeacher,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.primaryTeacher,
            unselectedLabelColor: Colors.grey.shade400,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: classNames.map((c) => Tab(text: 'Class $c')).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: classNames.map((className) {
                final assignments = grouped[className]!;
                assignments.sort((a, b) => a.date.compareTo(b.date));

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    final dateStr = DateFormat(
                      'EEEE, MMM dd',
                    ).format(assignment.date);
                    final hasSection =
                        assignment.sectionName != null &&
                        assignment.sectionName!.isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: Colors.white),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeacher.withOpacity(
                                    0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.book_rounded,
                                  size: 24,
                                  color: AppColors.primaryTeacher,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      assignment.subjectName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: Color(0xFF1A1C1E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        color: AppColors.primaryTeacher,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  Icons.person_rounded,
                                  'Examiner',
                                  assignment.examinerName,
                                ),
                                if (hasSection) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    Icons.grid_view_rounded,
                                    'Section',
                                    assignment.sectionName!,
                                  ),
                                ],
                                if (assignment.syllabus != null &&
                                    assignment.syllabus!.isNotEmpty &&
                                    assignment.syllabus != "N/A") ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    Icons.description_rounded,
                                    'Syllabus',
                                    assignment.syllabus!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1A1C1E),
            ),
          ),
        ),
      ],
    );
  }
}

class TeacherExamDetailsSheet extends StatefulWidget {
  final Exam exam;
  final ScrollController scrollController;

  const TeacherExamDetailsSheet({
    super.key,
    required this.exam,
    required this.scrollController,
  });

  @override
  State<TeacherExamDetailsSheet> createState() => _TeacherExamDetailsSheetState();
}

class _TeacherExamDetailsSheetState extends State<TeacherExamDetailsSheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 0
                            ? AppColors.primaryTeacher
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedIndex == 0
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryTeacher.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Routines & Syllabus',
                        style: TextStyle(
                          color: _selectedIndex == 0
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 1
                            ? AppColors.primaryTeacher
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedIndex == 1
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryTeacher.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Results',
                        style: TextStyle(
                          color: _selectedIndex == 1
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _selectedIndex == 0
              ? TeacherExamRoutineView(
                  exam: widget.exam,
                  scrollController: widget.scrollController,
                )
              : TeacherExamResultsView(
                  exam: widget.exam,
                  scrollController: widget.scrollController,
                ),
        ),
      ],
    );
  }
}

class TeacherExamResultsView extends StatelessWidget {
  final Exam exam;
  final ScrollController scrollController;

  const TeacherExamResultsView({
    super.key,
    required this.exam,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (exam.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No results published yet.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Group results by Subject for a structured view
    final grouped = <String, List<Result>>{};
    for (var r in exam.results) {
      final subjectName = r.subject?.name ?? r.subjectId ?? 'Unknown Subject';
      grouped.putIfAbsent(subjectName, () => []).add(r);
    }
    final subjectNames = grouped.keys.toList()..sort();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: subjectNames.length,
      itemBuilder: (context, index) {
        final subjectName = subjectNames[index];
        final subjectResults = grouped[subjectName]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.book_outlined, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        subjectName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${subjectResults.length} Marks',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subjectResults.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, idx) {
                    final res = subjectResults[idx];
                    final isPass = res.totalMarks > 0 && (res.marksObtained / res.totalMarks) >= 0.4;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                res.studentId, // We might not have the student name easily available
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (res.remarks.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  res.remarks,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPass ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${res.marksObtained.toStringAsFixed(1)} / ${res.totalMarks.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: isPass ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
