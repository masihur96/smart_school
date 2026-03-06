import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/teacher_provider.dart';
import '../providers/student_provider.dart';

class TeacherManagementScreen extends ConsumerWidget {
  const TeacherManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachers = ref.watch(teachersProvider);
    final classes = ref.watch(classesProvider);
    final subjects = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/teachers/add'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: teachers.length,
        itemBuilder: (context, index) {
          final teacher = teachers[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(teacher.user?.name ?? 'Unknown Teacher'),
            subtitle: Text('${teacher.user?.email} | ${teacher.assignedSubjects.length} subjects'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Edit teacher
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/teachers/add'),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
