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
import '../../../models/school_models.dart';

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

    if (routineNotifier.isLoading && routineNotifier.routineEntries.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final classId = currentUser.classId;
    if (classId == null) {
      return const Scaffold(body: Center(child: Text('Class information not found for student.')));
    }

    final entries = routineNotifier.routineEntries;
    final error = routineNotifier.error;

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
          title: const Text('My Routine'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Schedule', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Homework', icon: Icon(Icons.assignment)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () => routineNotifier.fetchRoutine(classId),
              child: _buildRoutineList(entries, routineNotifier, days),
            ),
            RefreshIndicator(
              onRefresh: () => context.read<StudentHomeworkNotifier>().fetchHomework(classId),
              child: _buildHomeworkList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineList(List<RoutineEntry> entries, StudentRoutineNotifier routineNotifier, List<String> days) {
    if (routineNotifier.isLoading && entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (entries.isEmpty && !routineNotifier.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No entries in routine yet.'),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final dayEntries = entries.where((e) => e.day == day).toList();
              if (dayEntries.isEmpty) return const SizedBox.shrink();

              return ExpansionTile(
                initiallyExpanded:
                    DateFormat('EEEE').format(DateTime.now()) == day,
                title: Text(
                  day,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: dayEntries.map((e) {
                  final subjectName = context
                      .read<SubjectSetupNotifier>()
                      .subjects
                      .firstWhere(
                        (s) => s.id == e.subjectId,
                        orElse: () => Subject(id: '', name: 'Unknown', code: ''),
                      )
                      .name;
                  final teacherName = context
                          .read<TeachersNotifier>()
                          .teachers
                          .firstWhere(
                            (t) => t.userId == e.teacherId,
                            orElse: () =>
                                Teacher(userId: '', assignedSubjects: []),
                          )
                          .user
                          ?.name ??
                      'Unknown';
                  return ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(subjectName),
                    subtitle: Text(
                      '$teacherName | ${e.startTime} - ${e.endTime} | Room: ${e.roomNumber ?? 'N/A'}',
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (routineNotifier.isLoading && entries.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildHomeworkList(BuildContext context) {
    final homeworkNotifier = context.watch<StudentHomeworkNotifier>();
    final homeworkList = homeworkNotifier.homeworkList;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

    if (homeworkNotifier.isLoading && homeworkList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (homeworkList.isEmpty && !homeworkNotifier.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No homework assigned.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: homeworkList.length,
      itemBuilder: (context, index) {
        final hw = homeworkList[index];
        final subName = subjects
            .firstWhere(
              (s) => s.id == hw.subjectId,
              orElse: () => Subject(id: '', name: 'Unknown'),
            )
            .name;
        final isOverdue = hw.dueDate.isBefore(DateTime.now());

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subName,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(hw.dueDate),
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  hw.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  hw.description,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
