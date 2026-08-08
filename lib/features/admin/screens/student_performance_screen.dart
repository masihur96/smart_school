import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/models/admin_dashboard_model.dart';
import 'package:smart_school/features/admin/providers/student_performance_provider.dart';

class StudentPerformanceScreen extends StatefulWidget {
  const StudentPerformanceScreen({super.key});

  @override
  State<StudentPerformanceScreen> createState() =>
      _StudentPerformanceScreenState();
}

class _StudentPerformanceScreenState extends State<StudentPerformanceScreen> {
  // Student search dropdown controller
  final TextEditingController _studentSearchController =
      TextEditingController();
  final FocusNode _studentSearchFocus = FocusNode();
  bool _showStudentDropdown = false;
  String _studentQuery = '';

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentPerformanceProvider>();
      // Always load current month/year on first open
      if (provider.allPerformances.isEmpty && !provider.isLoading) {
        provider.fetchPerformances();
      }
    });

    _studentSearchFocus.addListener(() {
      if (!_studentSearchFocus.hasFocus) {
        setState(() => _showStudentDropdown = false);
      }
    });
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    _studentSearchFocus.dispose();
    super.dispose();
  }

  double _score(StudentPerformance p) =>
      (p.attendance.percentage + p.homework.percentage + p.exams.percentage) /
      3;

  Color _gradeColor(double s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFF3B82F6);
    if (s >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _gradeLabel(double s) {
    if (s >= 80) return 'Excellent';
    if (s >= 60) return 'Good';
    if (s >= 40) return 'Average';
    return 'Needs Improvement';
  }

  IconData _gradeIcon(double s) {
    if (s >= 80) return Icons.emoji_events_rounded;
    if (s >= 60) return Icons.thumb_up_rounded;
    if (s >= 40) return Icons.trending_flat_rounded;
    return Icons.trending_down_rounded;
  }

  // ── Month picker bottom sheet ──────────────────────────────────────────
  void _showMonthPicker(StudentPerformanceProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Select Month',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${provider.selectedYear}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final isSelected = provider.selectedMonth == m;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.fetchForMonth(m, provider.selectedYear);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryAdmin,
                                  AppColors.primaryAdmin.withValues(alpha: 0.8),
                                ],
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryAdmin.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _months[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _studentSearchFocus.unfocus();
        setState(() => _showStudentDropdown = false);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryAdmin,
          title: Consumer<StudentPerformanceProvider>(
            builder: (context, provider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Student Performance", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_months[provider.selectedMonth - 1]} ${provider.selectedYear}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!provider.isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${provider.allPerformances.length} students',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),

          // actions: [
          //   Consumer<StudentPerformanceProvider>(
          //     builder: (context, provider, _) {
          //       return IconButton(
          //         icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          //         onPressed: () => provider.fetchPerformances(),
          //         tooltip: 'Refresh',
          //       );
          //     },
          //   ),
          // ],
        ),
        body: Consumer<StudentPerformanceProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              slivers: [
                // ── App Bar ───────────────────────────────────────────
                // _buildSliverAppBar(provider),

                // ── Filter bar ────────────────────────────────────────
                SliverToBoxAdapter(child: _buildFilterBar(provider)),

                // ── Student dropdown search ───────────────────────────
                SliverToBoxAdapter(
                  child: _buildStudentDropdownSearch(provider),
                ),

                // ── Body ─────────────────────────────────────────────
                if (provider.isLoading)
                  SliverToBoxAdapter(child: _buildLoadingState())
                else if (provider.error != null &&
                    provider.allPerformances.isEmpty)
                  SliverToBoxAdapter(child: _buildErrorState(provider))
                else if (provider.selectedStudent != null)
                  // Individual student detail
                  SliverToBoxAdapter(
                    child: _buildIndividualDetail(
                      provider.selectedStudent!,
                      provider,
                    ),
                  )
                else
                  // Full ranked list
                  _buildRankedList(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Sliver App Bar ──────────────────────────────────────────────────────
  Widget _buildSliverAppBar(StudentPerformanceProvider provider) {
    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryAdmin,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6A1B9A), AppColors.primaryAdmin],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Student Perfor mance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_months[provider.selectedMonth - 1]} ${provider.selectedYear}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!provider.isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${provider.allPerformances.length} students',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          provider.selectedStudent != null
              ? provider.selectedStudent!.name
              : 'Student Performance',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () => provider.fetchPerformances(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  // ── Filter Bar ──────────────────────────────────────────────────────────
  Widget _buildFilterBar(StudentPerformanceProvider provider) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);
    final classes = provider.availableClasses;
    final sections = provider.availableSections;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // ── Month chip ──────────────────────────────────
              _filterChip(
                icon: Icons.calendar_month_rounded,
                label: _months[provider.selectedMonth - 1],
                color: AppColors.primaryAdmin,
                onTap: () => _showMonthPicker(provider),
                trailing: Icons.keyboard_arrow_down_rounded,
              ),
              const SizedBox(width: 8),

              // ── Year dropdown ────────────────────────────────
              _dropdownChip<int>(
                icon: Icons.date_range_rounded,
                color: const Color(0xFF6366F1),
                value: provider.selectedYear,
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (y) {
                  if (y != null) {
                    provider.fetchForMonth(provider.selectedMonth, y);
                  }
                },
              ),
              const SizedBox(width: 8),

              // ── Class dropdown ───────────────────────────────
              if (classes.isNotEmpty) ...[
                _dropdownChip<String?>(
                  icon: Icons.class_rounded,
                  color: const Color(0xFF10B981),
                  hint: 'All Classes',
                  value: provider.filterClass,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Classes'),
                    ),
                    ...classes.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: provider.setClassFilter,
                ),
                const SizedBox(width: 8),
              ],

              // ── Section dropdown ─────────────────────────────
              if (sections.isNotEmpty) ...[
                _dropdownChip<String?>(
                  icon: Icons.group_work_rounded,
                  color: const Color(0xFFF59E0B),
                  hint: 'All Sections',
                  value: provider.filterSection,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Sections'),
                    ),
                    ...sections.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: provider.setSectionFilter,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 3),
              Icon(trailing, size: 13, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dropdownChip<T>({
    required IconData icon,
    required Color color,
    required List<DropdownMenuItem<T>> items,
    required T value,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              hint: hint != null
                  ? Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    )
                  : null,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 13,
                color: color,
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── Student Dropdown Search ─────────────────────────────────────────────
  Widget _buildStudentDropdownSearch(StudentPerformanceProvider provider) {
    final allNames = provider.studentNames;
    final filtered = _studentQuery.isEmpty
        ? allNames
        : allNames
              .where(
                (n) => n.toLowerCase().contains(_studentQuery.toLowerCase()),
              )
              .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  provider.selectedStudent != null
                      ? Icons.person_rounded
                      : Icons.search_rounded,
                  size: 18,
                  color: provider.selectedStudent != null
                      ? AppColors.primaryAdmin
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _studentSearchController,
                    focusNode: _studentSearchFocus,
                    onTap: () {
                      setState(() {
                        _showStudentDropdown = true;
                        _studentQuery = '';
                        _studentSearchController.clear();
                      });
                    },
                    onChanged: (v) {
                      setState(() {
                        _studentQuery = v;
                        _showStudentDropdown = true;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: provider.selectedStudent != null
                          ? provider.selectedStudent!.name
                          : 'Search student for individual report...',
                      hintStyle: TextStyle(
                        color: provider.selectedStudent != null
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (provider.selectedStudent != null) ...[
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () {
                      _studentSearchController.clear();
                      setState(() {
                        _studentQuery = '';
                        _showStudentDropdown = false;
                      });
                      provider.clearSelectedStudent();
                    },
                    color: Colors.grey.shade500,
                    tooltip: 'Clear selection',
                  ),
                ] else ...[
                  const SizedBox(width: 12),
                ],
              ],
            ),

            // Dropdown list
            if (_showStudentDropdown && allNames.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 2),

                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No student found',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, indent: 48),
                        itemBuilder: (context, i) {
                          final name = filtered[i];
                          final isSelected =
                              provider.selectedStudent?.name == name;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryAdmin
                                  .withValues(alpha: 0.1),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primaryAdmin
                                    : null,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: AppColors.primaryAdmin,
                                  )
                                : null,
                            onTap: () {
                              _studentSearchController.text = name;
                              _studentSearchFocus.unfocus();
                              setState(() {
                                _showStudentDropdown = false;
                                _studentQuery = '';
                              });
                              provider.selectStudentByName(name);
                            },
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Individual Student Detail ────────────────────────────────────────────
  Widget _buildIndividualDetail(
    StudentPerformance perf,
    StudentPerformanceProvider provider,
  ) {
    final score = _score(perf);
    final color = _gradeColor(score);
    final label = _gradeLabel(score);
    final icon = _gradeIcon(score);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Big avatar with ring
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 5,
                            backgroundColor: color.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            strokeCap: StrokeCap.round,
                          ),
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Text(
                              perf.name.isNotEmpty
                                  ? perf.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perf.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (perf.classInfo != null)
                            Row(
                              children: [
                                _infoChip(perf.classInfo!.name, Colors.purple),
                                if (perf.section != null) ...[
                                  const SizedBox(width: 6),
                                  _infoChip(
                                    perf.section!.name,
                                    const Color(0xFF6366F1),
                                  ),
                                ],
                              ],
                            ),
                          if (perf.rollNumber != null &&
                              perf.rollNumber!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Roll: ${perf.rollNumber}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Score badge
                    Column(
                      children: [
                        Text(
                          '${score.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(icon, size: 12, color: color),
                            const SizedBox(width: 3),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),

                // Three metric detail cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricDetailCard(
                        icon: Icons.how_to_reg_rounded,
                        label: 'Attendance',
                        percentage: perf.attendance.percentage,
                        detail1: '${perf.attendance.presentDays} present',
                        detail2:
                            '${perf.attendance.totalWorkingDays} working days',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricDetailCard(
                        icon: Icons.assignment_rounded,
                        label: 'Homework',
                        percentage: perf.homework.percentage,
                        detail1: '${perf.homework.totalDone} done',
                        detail2: '${perf.homework.totalAssigned} assigned',
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricDetailCard(
                        icon: Icons.assessment_rounded,
                        label: 'Exams',
                        percentage: perf.exams.percentage,
                        detail1:
                            '${perf.exams.totalMarksObtained.toStringAsFixed(0)} marks',
                        detail2:
                            '/ ${perf.exams.totalMaximumMarks.toStringAsFixed(0)} total',
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Period info
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Showing data for ${_months[provider.selectedMonth - 1]} ${provider.selectedYear}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDetailCard({
    required IconData icon,
    required String label,
    required double percentage,
    required String detail1,
    required String detail2,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const Spacer(),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail1,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            detail2,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Ranked List (all / filtered) ────────────────────────────────────────
  SliverList _buildRankedList(StudentPerformanceProvider provider) {
    final list = provider.filteredPerformances;

    if (list.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students found',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting the month or year filter',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == 0) {
          // Section header
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Ranked by Overall Score — ${list.length} students',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }
        final i = index - 1;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _buildRankedCard(list[i], rank: i + 1),
        );
      }, childCount: list.length + 1),
    );
  }

  Widget _buildRankedCard(StudentPerformance perf, {required int rank}) {
    final score = _score(perf);
    final color = _gradeColor(score);
    final label = _gradeLabel(score);

    final rankColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };
    final rankEmojis = {1: '🥇', 2: '🥈', 3: '🥉'};

    final isTop3 = rank <= 3;
    final medalColor = isTop3 ? rankColors[rank]! : Colors.grey.shade300;

    return GestureDetector(
      onTap: () {
        _studentSearchController.text = perf.name;
        setState(() {
          _studentQuery = '';
          _showStudentDropdown = false;
        });
        context.read<StudentPerformanceProvider>().selectStudentByName(
          perf.name,
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Rank badge
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    if (isTop3)
                      Text(
                        rankEmojis[rank]!,
                        style: const TextStyle(fontSize: 20),
                      )
                    else
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  perf.name.isNotEmpty ? perf.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + class info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perf.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (perf.classInfo != null) ...[
                          _infoChip(perf.classInfo!.name, Colors.purple),
                          const SizedBox(width: 5),
                        ],
                        if (perf.section != null)
                          Text(
                            perf.section!.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Mini metric bars row
                    Row(
                      children: [
                        Expanded(
                          child: _miniBar(
                            'Att',
                            perf.attendance.percentage,
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _miniBar(
                            'HW',
                            perf.homework.percentage,
                            const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _miniBar(
                            'Exam',
                            perf.exams.percentage,
                            const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Score ring
              SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 5,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          label.split(' ').first,
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 4,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── Loading / Error states ──────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Column(
      children: List.generate(5, (i) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Row(
                  children: [
                    // Rank badge placeholder
                    SizedBox(
                      width: 36,
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Avatar placeholder
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    // Name + class info placeholder
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                height: 16,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                height: 16,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Mini metric bars row placeholder
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Score ring placeholder
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(StudentPerformanceProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            provider.error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => provider.fetchPerformances(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAdmin,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
