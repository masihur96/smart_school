import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/l10n/app_localizations.dart';

import '../../../models/school_models.dart' hide Teacher;
import '../../auth/providers/auth_provider.dart';
import '../providers/student_homework_provider.dart';
import '../providers/student_routine_provider.dart';

class StudentRoutineScreen extends StatefulWidget {
  const StudentRoutineScreen({super.key});

  @override
  State<StudentRoutineScreen> createState() => _StudentRoutineScreenState();
}

class _StudentRoutineScreenState extends State<StudentRoutineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final currentUser = context.read<AuthNotifier>().user;
    if (currentUser == null || currentUser.classIds.isEmpty) return;

    if (mounted) {
      context.read<StudentRoutineNotifier>().fetchRoutine(
        currentUser.classIds.first,
      );
      context.read<StudentHomeworkNotifier>().fetchHomework(
        currentUser.classIds.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.watch<AuthNotifier>().user;
    if (currentUser == null) {
      return Scaffold(body: Center(child: Text(l10n.notLoggedIn)));
    }

    final routineNotifier = context.watch<StudentRoutineNotifier>();
    final homeworkNotifier = context.watch<StudentHomeworkNotifier>();

    final classId = currentUser.classIds.first;
    if (classId.isEmpty) {
      return Scaffold(body: Center(child: Text(l10n.classInfoNotFound)));
    }

    final entries = routineNotifier.routineEntries;

    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.academicSchedule,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryStudent,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                labelColor: AppColors.primaryStudent,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: l10n.routine),
                  Tab(text: l10n.homework),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () => routineNotifier.fetchRoutine(classId),
              child: _buildRoutineList(entries, routineNotifier, days),
            ),
            RefreshIndicator(
              onRefresh: () => homeworkNotifier.fetchHomework(classId),
              child: _buildHomeworkList(context, homeworkNotifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineList(
    List<RoutineEntry> entries,
    StudentRoutineNotifier routineNotifier,
    List<String> days,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (routineNotifier.isLoading && entries.isEmpty) {
      return _buildRoutineShimmer();
    }

    if (entries.isEmpty && !routineNotifier.isLoading) {
      return _buildEmptyState(
        icon: Icons.calendar_month_outlined,
        title: l10n.noScheduleYet,
        subtitle: l10n.noScheduleSubtitle,
      );
    }

    // Filter days that actually have entries
    final activeDays = days
        .where((d) => entries.any((e) => e.day == d))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: activeDays.length,
      itemBuilder: (context, index) {
        final day = activeDays[index];
        final dayEntries = entries.where((e) => e.day == day).toList();

        // Sort day entries by start time
        dayEntries.sort((a, b) => a.startTime.compareTo(b.startTime));

        final bool isToday = DateFormat('EEEE').format(DateTime.now()) == day;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text(
                    day.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isToday ? AppColors.primaryStudent : Colors.grey[500],
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStudent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.today.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryStudent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ...dayEntries.map((e) => _RoutineCard(entry: e)).toList(),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildHomeworkList(
    BuildContext context,
    StudentHomeworkNotifier homeworkNotifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final homeworkList = homeworkNotifier.homeworkList;

    if (homeworkNotifier.isLoading && homeworkList.isEmpty) {
      return _buildHomeworkShimmer();
    }

    if (homeworkList.isEmpty && !homeworkNotifier.isLoading) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: l10n.allAssignmentsDone,
        subtitle: l10n.noPendingHomeworkSubtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: homeworkList.length,
      itemBuilder: (context, index) {
        final sh = homeworkList[index];
        final hw = sh.homework;

        if (hw == null) return const SizedBox();

        return _HomeworkCard(sh: sh);
      },
    );
  }

  Widget _buildRoutineShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(width: 60, height: 14, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(width: 50, height: 11, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Container(height: 30, width: 1, color: Colors.grey[300]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(width: 100, height: 15, color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: const Icon(Icons.person_outline, size: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(width: 80, height: 12, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 50,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildHomeworkShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(width: 40, height: 14, color: Colors.white),
                          ),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 60,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(width: 150, height: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(width: double.infinity, height: 13, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(width: 200, height: 13, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.green.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final RoutineEntry entry;

  const _RoutineCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subjectName = entry.subjectEntity?.name ?? l10n.unknownSubject;
    final teacherName = entry.teacherEntity?.name ?? l10n.teacherNotAssigned;
    final room = entry.roomNumber ?? 'N/A';

    // Format times to look cleaner (e.g. 09:00:00 -> 09:00 AM)
    String formatTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return 'N/A';
      try {
        final time = DateFormat('HH:mm:ss').parse(timeStr);
        return DateFormat('hh:mm a', l10n.localeName).format(time);
      } catch (e) {
        return timeStr;
      }
    }

    final startTime = formatTime(entry.startTime);
    final endTime = formatTime(entry.endTime);

    return Card(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: AppColors.primaryStudent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          endTime,
                          style: TextStyle(
                            fontSize: 11,

                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Container(height: 30, width: 1),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subjectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  teacherName,
                                  style: TextStyle(fontSize: 12),
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.roomNumberFormat(room),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final StudentHomework sh;

  const _HomeworkCard({required this.sh});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hw = sh.homework!;
    final isDone = sh.status == 'done';
    final isSubmitted = sh.status == 'submitted';
    final isOverdue = hw.dueDate.isBefore(DateTime.now()) && !isDone && !isSubmitted;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isDone) {
      statusColor = const Color(0xFF10B981);
      statusText = l10n.completedStatus;
      statusIcon = Icons.check_circle;
    } else if (isSubmitted) {
      statusColor = const Color(0xFF3B82F6);
      statusText = l10n.submittedStatus;
      statusIcon = Icons.send;
    } else if (isOverdue) {
      statusColor = const Color(0xFFEF4444);
      statusText = l10n.overdue;
      statusIcon = Icons.error_outline;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusText = l10n.pending;
      statusIcon = Icons.pending_actions;
    }

    final subjectName = hw.subjectInfo?.name ?? l10n.unknownSubject;
    final formattedDate = DateFormat('EEEE, MMM d, yyyy', l10n.localeName).format(hw.dueDate);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Future functionality can be added here
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryStudent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.book_outlined,
                      color: AppColors.primaryStudent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          style: const TextStyle(
                            color: AppColors.primaryStudent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hw.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(color: statusColor, text: statusText, icon: statusIcon),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                hw.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: isOverdue ? Colors.red : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${l10n.due}: $formattedDate',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isOverdue ? Colors.red : Colors.grey.shade700,
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
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String text;
  final IconData icon;

  const _StatusChip({required this.color, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
