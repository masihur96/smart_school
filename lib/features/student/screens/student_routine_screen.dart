import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/models/teacher_model.dart';
import '../../admin/providers/routine_provider.dart';
import '../../admin/providers/student_provider.dart';
import '../../admin/providers/teacher_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/school_models.dart';

class StudentRoutineScreen extends ConsumerWidget {
  const StudentRoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final student = ref.watch(studentsProvider).firstWhere((s) => s.userId == currentUser.id);
    final routineMap = ref.watch(routineProvider);
    final key = '${student.classId}_${student.sectionId}';
    final entries = routineMap[key] ?? [];

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routine'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: entries.isEmpty
          ? const Center(child: Text('No entries in routine yet.'))
          : ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final dayEntries = entries.where((e) => e.day == day).toList();
                if (dayEntries.isEmpty) return const SizedBox.shrink();

                return ExpansionTile(
                  initiallyExpanded: DateFormat('EEEE').format(DateTime.now()) == day,
                  title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: dayEntries.map((e) {
                    final subjectName = ref.read(subjectsProvider).firstWhere((s) => s.id == e.subjectId).name;
                    final teacherName = ref.read(teachersProvider).firstWhere((t) => t.userId == e.teacherId, orElse: () => Teacher(userId: '', assignedSubjects: [])).user?.name ?? 'Unknown';
                    return ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(subjectName),
                      subtitle: Text('$teacherName | ${e.startTime} - ${e.endTime}'),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}
