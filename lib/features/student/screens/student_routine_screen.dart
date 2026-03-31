import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:smart_school/models/teacher_model.dart';
import '../providers/student_routine_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routine'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => routineNotifier.fetchRoutine(classId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (entries.isEmpty && !routineNotifier.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No entries in routine yet.'),
                  ),
                )
              else
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
        ),
      ),
    );
  }
}
