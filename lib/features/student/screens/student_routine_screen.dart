import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:smart_school/models/teacher_model.dart';
import '../providers/student_routine_provider.dart';
import '../providers/student_homework_provider.dart';
import '../../admin/providers/student_provider.dart';
import '../../admin/providers/setup_provider.dart';
import '../../admin/providers/teacher_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/school_models.dart' hide Teacher;

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
    if (currentUser == null || currentUser.classId == null) return;

    if (mounted) {
      context.read<StudentRoutineNotifier>().fetchRoutine(currentUser.classId!);
      context.read<StudentHomeworkNotifier>().fetchHomework(currentUser.classId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthNotifier>().user;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final routineNotifier = context.watch<StudentRoutineNotifier>();
    final homeworkNotifier = context.watch<StudentHomeworkNotifier>();

    if (routineNotifier.isLoading && routineNotifier.routineEntries.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final classId = currentUser.classId;
    if (classId == null) {
      return const Scaffold(
        body: Center(child: Text('Class information not found for student.')),
      );
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
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('Academic Schedule',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
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
              child: const TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                labelColor: Colors.green,
                unselectedLabelColor: Colors.white,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Routine'),
                  Tab(text: 'Homework'),
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

  Widget _buildRoutineList(List<RoutineEntry> entries,
      StudentRoutineNotifier routineNotifier, List<String> days) {
    if (entries.isEmpty && !routineNotifier.isLoading) {
      return _buildEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No Schedule Yet',
        subtitle: 'Your weekly class routine will appear here.',
      );
    }

    // Filter days that actually have entries
    final activeDays = days.where((d) => entries.any((e) => e.day == d)).toList();

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
                      color: isToday ? Colors.green : Colors.grey[500],
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
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
      BuildContext context, StudentHomeworkNotifier homeworkNotifier) {
    final homeworkList = homeworkNotifier.homeworkList;

    if (homeworkNotifier.isLoading && homeworkList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (homeworkList.isEmpty && !homeworkNotifier.isLoading) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: 'All Assignments Done',
        subtitle: 'No pending homework for your class.',
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

  Widget _buildEmptyState(
      {required IconData icon, required String title, required String subtitle}) {
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
    final subjectName = entry.subjectEntity?.name ?? 'Unknown Subject';
    final teacherName = entry.teacherEntity?.name ?? 'Teacher Not Assigned';
    final room = entry.roomNumber ?? 'N/A';
    
    // Format times to look cleaner (e.g. 09:00:00 -> 09:00 AM)
    String formatTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return 'N/A';
      try {
        final time = DateFormat('HH:mm:ss').parse(timeStr);
        return DateFormat('hh:mm a').format(time);
      } catch (e) {
        return timeStr;
      }
    }

    final startTime = formatTime(entry.startTime);
    final endTime = formatTime(entry.endTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: Colors.green,
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
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          endTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[200],
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
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  teacherName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Room: $room',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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
    final hw = sh.homework!;
    final isDone = sh.status == 'done';
    final isSubmitted = sh.status == 'submitted';
    final isOverdue = hw.dueDate.isBefore(DateTime.now()) && !isDone;

    Color statusColor;
    String statusText;

    if (isDone) {
      statusColor = const Color(0xFF10B981);
      statusText = 'Completed';
    } else if (isSubmitted) {
      statusColor = const Color(0xFF3B82F6);
      statusText = 'Submitted';
    } else if (isOverdue) {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Overdue';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
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
                    Text(
                      DateFormat('MMM d').format(hw.dueDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : Colors.grey[500],
                      ),
                    ),
                    _StatusChip(color: statusColor, text: statusText),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  hw.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hw.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String text;

  const _StatusChip({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
