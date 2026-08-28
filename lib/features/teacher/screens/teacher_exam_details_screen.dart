import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart';

class TeacherExamDetailsScreen extends StatefulWidget {
  final Exam exam;

  const TeacherExamDetailsScreen({super.key, required this.exam});

  @override
  State<TeacherExamDetailsScreen> createState() =>
      _TeacherExamDetailsScreenState();
}

class _TeacherExamDetailsScreenState extends State<TeacherExamDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final dateRange = _formatDateRange(exam);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primaryTeacher,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryTeacher,
                      AppColors.primaryTeacher.withOpacity(0.75),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: exam.isPublished
                                    ? Colors.white.withOpacity(0.25)
                                    : Colors.orange.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    exam.isPublished
                                        ? Icons.check_circle_rounded
                                        : Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    exam.isPublished ? 'Published' : 'Draft',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (dateRange.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        color: Colors.white, size: 12),
                                    const SizedBox(width: 5),
                                    Text(
                                      dateRange,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          exam.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (exam.description != null &&
                            exam.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            exam.description!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryTeacher,
                  indicatorWeight: 3,
                  labelColor: AppColors.primaryTeacher,
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Routine'),
                    Tab(text: 'Syllabus'),
                    Tab(text: 'Result'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _RoutineTab(exam: exam),
            _SyllabusTab(exam: exam),
            _ResultTab(exam: exam),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(Exam exam) {
    if (exam.startDate == null) return '';
    final start = DateFormat('MMM dd').format(exam.startDate!);
    if (exam.endDate == null) return start;
    final end = DateFormat('MMM dd').format(exam.endDate!);
    return '$start – $end';
  }
}

// ---------------------------------------------------------------------------
// ROUTINE TAB
// ---------------------------------------------------------------------------
class _RoutineTab extends StatelessWidget {
  final Exam exam;
  const _RoutineTab({required this.exam});

  @override
  Widget build(BuildContext context) {
    if (exam.assignments.isEmpty) {
      return _emptyState(
        icon: Icons.event_note_outlined,
        message: 'No exam routines assigned yet.',
      );
    }

    // Group by class
    final grouped = <String, List<ExamAssignment>>{};
    for (final a in exam.assignments) {
      grouped.putIfAbsent(a.className, () => []).add(a);
    }
    final classNames = grouped.keys.toList()..sort();

    return DefaultTabController(
      length: classNames.length,
      child: Column(
        children: [
          if (classNames.length > 1)
            Container(
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primaryTeacher,
                labelColor: AppColors.primaryTeacher,
                unselectedLabelColor: Colors.grey.shade400,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: classNames.map((c) => Tab(text: 'Class $c')).toList(),
              ),
            ),
          Expanded(
            child: classNames.length == 1
                ? _buildAssignmentList(grouped[classNames.first]!)
                : TabBarView(
                    children: classNames
                        .map((c) => _buildAssignmentList(grouped[c]!))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentList(List<ExamAssignment> items) {
    final sorted = [...items]..sort((a, b) => a.date.compareTo(b.date));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, i) => _RoutineCard(assignment: sorted[i]),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final ExamAssignment assignment;
  const _RoutineCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEE, MMM dd yyyy').format(assignment.date);
    final isToday = _isToday(assignment.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isToday
            ? Border.all(color: AppColors.primaryTeacher, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeacher.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.book_rounded,
                      color: AppColors.primaryTeacher, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.subjectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Class ${assignment.className}${assignment.sectionName != null && assignment.sectionName!.isNotEmpty ? ' – ${assignment.sectionName}' : ''}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeacher,
                      borderRadius: BorderRadius.circular(10),
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _row(Icons.calendar_today, 'Date', dateStr),
                  const SizedBox(height: 8),
                  _row(Icons.person_rounded, 'Examiner',
                      assignment.examinerName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1E)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SYLLABUS TAB
// ---------------------------------------------------------------------------
class _SyllabusTab extends StatelessWidget {
  final Exam exam;
  const _SyllabusTab({required this.exam});

  @override
  Widget build(BuildContext context) {
    final withSyllabus = exam.assignments
        .where((a) =>
            a.syllabus != null &&
            a.syllabus!.isNotEmpty &&
            a.syllabus != 'N/A')
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (withSyllabus.isEmpty) {
      return _emptyState(
        icon: Icons.description_outlined,
        message: 'No syllabus information available.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: withSyllabus.length,
      itemBuilder: (context, i) {
        final a = withSyllabus[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.description_rounded,
                          color: Colors.blue.shade700, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.subjectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A1C1E),
                            ),
                          ),
                          Text(
                            'Class ${a.className}${a.sectionName != null && a.sectionName!.isNotEmpty ? ' – ${a.sectionName}' : ''}  •  ${DateFormat('MMM dd').format(a.date)}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    a.syllabus!,
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// RESULT TAB
// ---------------------------------------------------------------------------
class _ResultTab extends StatelessWidget {
  final Exam exam;
  const _ResultTab({required this.exam});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthNotifier>().user?.id ?? '';

    // If result is published — show results
    if (exam.isPublished) {
      return _buildPublishedResults(context);
    }

    // If NOT published — show only subjects this teacher is the examiner for
    return _buildMyAssignedSubjects(context, currentUserId);
  }

  Widget _buildPublishedResults(BuildContext context) {
    if (exam.results.isEmpty) {
      return _emptyState(
        icon: Icons.bar_chart_rounded,
        message: 'Results are published but no data is available yet.',
      );
    }

    final grouped = <String, List<Result>>{};
    for (final r in exam.results) {
      final key = r.subject?.name ?? r.subjectId ?? 'Unknown Subject';
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final subjects = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      itemBuilder: (context, i) {
        final subjectName = subjects[i];
        final results = grouped[subjectName]!;
        return _ResultSubjectCard(
            subjectName: subjectName, results: results);
      },
    );
  }

  Widget _buildMyAssignedSubjects(
      BuildContext context, String currentUserId) {
    // Filter assignments where the logged-in teacher is the examiner
    final myAssignments = exam.assignments
        .where((a) => a.examinerId == currentUserId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Results not published yet. Showing your assigned subjects for this exam.',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (myAssignments.isEmpty) {
      return Column(
        children: [
          header,
          Expanded(
            child: _emptyState(
              icon: Icons.assignment_ind_outlined,
              message: 'You have no subjects assigned for this exam.',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        header,
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: myAssignments.length,
            itemBuilder: (context, i) =>
                _AssignedSubjectCard(assignment: myAssignments[i]),
          ),
        ),
      ],
    );
  }
}

class _AssignedSubjectCard extends StatelessWidget {
  final ExamAssignment assignment;
  const _AssignedSubjectCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final examDate = assignment.date;
    final daysLeft = examDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    final isToday = daysLeft == 0;
    final isPast = daysLeft < 0;

    final String countdownLabel;
    final Color countdownColor;
    final Color countdownBg;
    if (isToday) {
      countdownLabel = 'TODAY';
      countdownColor = Colors.white;
      countdownBg = AppColors.primaryTeacher;
    } else if (isPast) {
      countdownLabel = 'OVERDUE';
      countdownColor = Colors.red.shade700;
      countdownBg = Colors.red.shade50;
    } else if (daysLeft == 1) {
      countdownLabel = 'TOMORROW';
      countdownColor = Colors.orange.shade800;
      countdownBg = Colors.orange.shade50;
    } else {
      countdownLabel = 'IN $daysLeft DAYS';
      countdownColor = Colors.blue.shade700;
      countdownBg = Colors.blue.shade50;
    }

    final hasSyllabus = assignment.syllabus != null &&
        assignment.syllabus!.isNotEmpty &&
        assignment.syllabus != 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isToday
            ? Border.all(color: AppColors.primaryTeacher, width: 1.5)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? AppColors.primaryTeacher.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isPast
                        ? [Colors.red.shade300, Colors.red.shade600]
                        : [
                            AppColors.primaryTeacher,
                            AppColors.primaryTeacher.withValues(alpha: 0.5),
                          ],
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeacher.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.primaryTeacher,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignment.subjectName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: Color(0xFF1A1C1E),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.school_rounded,
                                        size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Class ${assignment.className}'
                                      '${assignment.sectionName != null && assignment.sectionName!.isNotEmpty ? ' · ${assignment.sectionName}' : ''}',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Countdown badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: countdownBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              countdownLabel,
                              style: TextStyle(
                                color: countdownColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Info grid
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            _infoRow(
                              icon: Icons.event_rounded,
                              label: 'Exam Date',
                              value: DateFormat('EEEE, MMM dd yyyy')
                                  .format(examDate),
                              valueColor: isToday
                                  ? AppColors.primaryTeacher
                                  : isPast
                                      ? Colors.red.shade600
                                      : const Color(0xFF1A1C1E),
                            ),
                            const SizedBox(height: 10),
                            _infoRow(
                              icon: Icons.person_pin_rounded,
                              label: 'Examiner',
                              value: assignment.examinerName,
                            ),
                            if (hasSyllabus) ...[
                              const SizedBox(height: 10),
                              _infoRow(
                                icon: Icons.format_list_bulleted_rounded,
                                label: 'Syllabus',
                                value: assignment.syllabus!,
                                maxLines: 2,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Footer status strip
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_top_rounded,
                                    size: 12,
                                    color: Colors.orange.shade700),
                                const SizedBox(width: 5),
                                Text(
                                  'Mark Entry Pending',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (!isPast)
                            Text(
                              daysLeft == 0
                                  ? 'Exam is today!'
                                  : daysLeft == 1
                                      ? '1 day remaining'
                                      : '$daysLeft days remaining',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
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

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment:
          maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF1A1C1E),
              height: maxLines > 1 ? 1.4 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultSubjectCard extends StatelessWidget {
  final String subjectName;
  final List<Result> results;
  const _ResultSubjectCard(
      {required this.subjectName, required this.results});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.book_outlined,
                      color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    subjectName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${results.length} Students',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...results.map((r) {
              final isPass = r.totalMarks > 0 &&
                  (r.marksObtained / r.totalMarks) >= 0.4;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.studentId,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF1A1C1E),
                            ),
                          ),
                          if (r.remarks.isNotEmpty)
                            Text(
                              r.remarks,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPass
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${r.marksObtained.toStringAsFixed(1)} / ${r.totalMarks.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: isPass
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared empty state helper
// ---------------------------------------------------------------------------
Widget _emptyState({required IconData icon, required String message}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 72, color: Colors.grey.shade200),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}
