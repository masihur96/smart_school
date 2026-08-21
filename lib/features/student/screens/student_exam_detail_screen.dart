import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/l10n/app_localizations.dart';

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
      if (!mounted) return;
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

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return const Color(0xFF10B981);
      case 'B':
        return const Color(0xFF3B82F6);
      case 'C':
        return const Color(0xFFF59E0B);
      case 'D':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryStudent,
              foregroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildExamHeaderHero(),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryStudent,
                    unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                    indicatorColor: AppColors.primaryStudent,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Routine'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Syllabus'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Results'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRoutineTab(),
            _buildSyllabusTab(),
            _buildResultsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildExamHeaderHero() {
    final startDateStr = widget.exam.startDate != null
        ? DateFormat('MMM dd, yyyy').format(widget.exam.startDate!)
        : null;
    final endDateStr = widget.exam.endDate != null
        ? DateFormat('MMM dd, yyyy').format(widget.exam.endDate!)
        : null;

    final dateRangeText = (startDateStr != null && endDateStr != null)
        ? '$startDateStr - $endDateStr'
        : (startDateStr ?? endDateStr ?? 'Dates to be announced');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryStudent,
            AppColors.primaryStudent.withValues(alpha: 0.85),
            const Color(0xFF1E1B4B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.exam.isPublished
                          ? const Color(0xFF10B981).withValues(alpha: 0.25)
                          : Colors.amber.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.exam.isPublished
                            ? const Color(0xFF34D399)
                            : Colors.amberAccent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.exam.isPublished
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.exam.isPublished
                              ? 'Results Published'
                              : 'Upcoming / In Progress',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.exam.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.exam.description != null &&
                  widget.exam.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.exam.description!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateRangeText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ROUTINE TAB ====================

  Widget _buildRoutineTab() {
    return Consumer<StudentExamNotifier>(
      builder: (context, p, child) {
        if (p.isLoading) return _buildRoutineShimmer();
        if (p.routine.isEmpty) {
          return _buildEmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'No Exam Routine Available',
            subtitle: 'The schedule for this examination has not been posted yet.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(
              title: 'Examination Schedule',
              subtitle: '${p.routine.length} Subject${p.routine.length > 1 ? 's' : ''} Scheduled',
              icon: Icons.event_note_rounded,
            ),
            const SizedBox(height: 12),
            ...List.generate(p.routine.length, (index) {
              final assignment = p.routine[index];
              return _buildRoutineCard(assignment, index, p.routine.length);
            }),
          ],
        );
      },
    );
  }

  Widget _buildRoutineCard(ExamAssignment a, int index, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = a.date;
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isPast = date.isBefore(DateTime.now()) && !isToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppColors.primaryStudent.withValues(alpha: 0.6)
              : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Date Badge Column
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primaryStudent
                      : (isPast
                          ? (isDark ? Colors.grey[800] : Colors.grey[200])
                          : AppColors.primaryStudent.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? Colors.white
                            : (isPast
                                ? (isDark ? Colors.grey[400] : Colors.grey[600])
                                : AppColors.primaryStudent),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd').format(date),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isToday
                            ? Colors.white
                            : (isPast
                                ? (isDark ? Colors.grey[300] : Colors.grey[800])
                                : AppColors.primaryStudent),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEE').format(date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? Colors.white.withValues(alpha: 0.9)
                            : (isPast
                                ? (isDark ? Colors.grey[500] : Colors.grey[500])
                                : AppColors.primaryStudent.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),

              // Subject and Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.subjectName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryStudent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 15,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .examinerLabel(a.examinerName),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (a.className.isNotEmpty ||
                          (a.sectionName != null && a.sectionName!.isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (a.className.isNotEmpty)
                              _buildChip(
                                icon: Icons.class_outlined,
                                label: a.className,
                                isDark: isDark,
                              ),
                            if (a.sectionName != null &&
                                a.sectionName!.isNotEmpty)
                              _buildChip(
                                icon: Icons.group_outlined,
                                label: 'Sec: ${a.sectionName}',
                                isDark: isDark,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SYLLABUS TAB ====================

  Widget _buildSyllabusTab() {
    return Consumer<StudentExamNotifier>(
      builder: (context, p, child) {
        if (p.isLoading) return _buildSyllabusShimmer();
        final syllabusItems = p.syllabus
            .where((a) => a.syllabus != null && a.syllabus!.trim().isNotEmpty)
            .toList();

        if (syllabusItems.isEmpty) {
          return _buildEmptyState(
            icon: Icons.import_contacts_outlined,
            title: 'No Syllabus Outline',
            subtitle: 'Detailed syllabus topic descriptions have not been published yet.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(
              title: 'Exam Topics & Syllabus',
              subtitle: 'Study guidance for ${syllabusItems.length} Subject${syllabusItems.length > 1 ? 's' : ''}',
              icon: Icons.menu_book_rounded,
            ),
            const SizedBox(height: 12),
            ...syllabusItems.map((item) => _buildSyllabusCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildSyllabusCard(ExamAssignment item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial =
        item.subjectName.isNotEmpty ? item.subjectName[0].toUpperCase() : '?';

    final lines = (item.syllabus ?? '')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryStudent,
                  AppColors.primaryStudent.withValues(alpha: 0.75),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          title: Text(
            item.subjectName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          subtitle: Text(
            'Examiner: ${item.examinerName}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (lines.length <= 1) ...[
                    Text(
                      item.syllabus ?? 'No details provided.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ] else ...[
                    ...lines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.primaryStudent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                line.replaceAll(RegExp(r'^[\-\*\•]\s*'), ''),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== RESULTS TAB ====================

  Widget _buildResultsTab() {
    return Consumer<StudentExamNotifier>(
      builder: (context, p, child) {
        if (p.isLoading) return _buildResultsShimmer();

        if (p.results.isEmpty || !widget.exam.isPublished) {
          return _buildEmptyState(
            icon: Icons.assessment_outlined,
            title: 'Results Not Published',
            subtitle: widget.exam.isPublished
                ? 'No exam mark entries found for your account.'
                : 'The official results for this exam have not been published by the school yet.',
          );
        }

        return _buildResultsList(p.results);
      },
    );
  }

  Widget _buildResultsList(List<Result> results) {
    double totalObtained = 0;
    double totalMax = 0;
    int passCount = 0;

    for (var r in results) {
      totalObtained += r.marksObtained;
      totalMax += r.totalMarks;
      final pct = r.totalMarks > 0 ? (r.marksObtained / r.totalMarks) * 100 : 0.0;
      if (pct >= 33.0) passCount++;
    }

    final overallPercentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
    final overallGrade = _calculateGrade(overallPercentage);
    final overallGradeColor = _getGradeColor(overallGrade);

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildOverallSummaryCard(
          obtained: totalObtained,
          max: totalMax,
          percentage: overallPercentage,
          grade: overallGrade,
          gradeColor: overallGradeColor,
          passedSubjects: passCount,
          totalSubjects: results.length,
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(
          title: 'Subject Performance Breakdown',
          subtitle: '${results.length} Evaluated Subject${results.length > 1 ? 's' : ''}',
          icon: Icons.fact_check_rounded,
        ),
        const SizedBox(height: 12),
        ...results.map((r) => _buildResultCard(r)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOverallSummaryCard({
    required double obtained,
    required double max,
    required double percentage,
    required String grade,
    required Color gradeColor,
    required int passedSubjects,
    required int totalSubjects,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF311B92)]
              : [
                  AppColors.primaryStudent,
                  const Color(0xFF3730A3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStudent.withValues(alpha: 0.3),
            blurRadius: 16,
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
                    'Overall Performance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: gradeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Grade $grade',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Gauge / Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      strokeWidth: 7,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                    ),
                  ),
                  Icon(
                    grade == 'F'
                        ? Icons.warning_amber_rounded
                        : Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  icon: Icons.scoreboard_rounded,
                  label: 'Total Marks',
                  value:
                      '${obtained.toStringAsFixed(obtained.truncateToDouble() == obtained ? 0 : 1)} / ${max.toStringAsFixed(max.truncateToDouble() == max ? 0 : 1)}',
                ),
                Container(height: 24, width: 1, color: Colors.white24),
                _buildSummaryStat(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Subjects Passed',
                  value: '$passedSubjects of $totalSubjects',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(Result result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = result.totalMarks > 0
        ? (result.marksObtained / result.totalMarks)
        : 0.0;
    final pctScore = percentage * 100;
    final grade = _calculateGrade(pctScore);
    final gradeColor = _getGradeColor(grade);
    final subjectName = result.subject?.name ?? 'Subject';
    final teacherName = result.teacher?.name ?? 'Teacher N/A';
    final initial = subjectName.isNotEmpty ? subjectName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: gradeColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              teacherName,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gradeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        result.marksObtained.toStringAsFixed(
                          result.marksObtained.truncateToDouble() ==
                                  result.marksObtained
                              ? 0
                              : 1,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: gradeColor,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '/ ${result.totalMarks.toStringAsFixed(result.totalMarks.truncateToDouble() == result.totalMarks ? 0 : 1)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar & Percentage
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${pctScore.toStringAsFixed(1)}% ($grade)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: gradeColor,
                    ),
                  ),
                ),
              ],
            ),
            if (result.remarks.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252525) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.comment_bank_outlined,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Remarks: ${result.remarks}',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryStudent),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryStudent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primaryStudent.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SHIMMER SKELETONS ====================

  Widget _buildRoutineShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 140,
                        height: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 100,
                        height: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyllabusShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 120,
                          height: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 80,
                          height: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
