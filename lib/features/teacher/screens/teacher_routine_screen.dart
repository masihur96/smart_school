import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/school_models.dart';
import '../../admin/providers/routine_provider.dart';
import '../../auth/providers/auth_provider.dart';

class TeacherRoutineScreen extends StatefulWidget {
  const TeacherRoutineScreen({super.key});

  @override
  State<TeacherRoutineScreen> createState() => _TeacherRoutineScreenState();
}

class _TeacherRoutineScreenState extends State<TeacherRoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);

    // Set initial tab to current day
    final currentDay = _getCurrentDay();
    final dayIndex = _days.indexOf(currentDay);
    if (dayIndex != -1) {
      _tabController.index = dayIndex;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      if (user != null) {
        context.read<RoutineNotifier>().fetchTeacherRoutine(user.id);
      }
    });
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    final routineNotifier = context.watch<RoutineNotifier>();
    final teacherRoutine = routineNotifier.teacherRoutine
        .where((r) => r.teacherId == user?.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Class Routine'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: routineNotifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _days.map((day) {
                final dayEntries = teacherRoutine
                    .where((e) => e.day == day)
                    .toList();

                if (dayEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No classes scheduled for $day',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort by start time (crude sort)
                dayEntries.sort((a, b) => a.startTime.compareTo(b.startTime));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = dayEntries[index];
                    return _RoutineCard(entry: entry);
                  },
                );
              }).toList(),
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
    final className = entry.classEntity?.name ?? 'Unknown Class';
    final sectionName = entry.sectionEntity?.name ?? '';

    final classDisplay = sectionName.isNotEmpty
        ? '$className ($sectionName)'
        : className;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.startTime} - ${entry.endTime}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.class_, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Class: $classDisplay',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (entry.teacherEntity != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Teacher: ${entry.teacherEntity!.name}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            if (entry.roomNumber != null && entry.roomNumber!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.room, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Room: ${entry.roomNumber}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
