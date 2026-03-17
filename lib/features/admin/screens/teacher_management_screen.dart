import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_school/features/admin/screens/add_edit_teacher_screen.dart';
import '../providers/teacher_provider.dart';
import '../providers/setup_provider.dart';

class TeacherManagementScreen extends StatelessWidget {
  const TeacherManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teachers = context.watch<TeachersNotifier>().teachers;
    final classes = context.watch<ClassSetupNotifier>().classes;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

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
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_)=>AddEditTeacherScreen(),),);

        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
