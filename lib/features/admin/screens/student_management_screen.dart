import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_school/features/admin/screens/add_edit_student_screen.dart';
import '../providers/student_provider.dart';
import '../../../services/database_service.dart';
import '../../../models/school_models.dart';
import 'package:flutter/material.dart';

class StudentManagementScreen extends StatelessWidget {
  final bool hideAppBar;
  const StudentManagementScreen({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final studentsNotifier = context.watch<StudentsNotifier>();
    final students = studentsNotifier.students;
    final dbService = context.watch<DatabaseService>();
    final classes = dbService.classes;
    final sections = dbService.sections;

    return Scaffold(
      appBar: hideAppBar
          ? null
          : AppBar(
              title: const Text('Student Management'),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context.push('/admin/students/add'),
                ),
              ],
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: classes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: sections
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {},
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(student.user?.name[0] ?? '?'),
                  ),
                  title: Text(student.user?.name ?? 'Unknown'),
                  subtitle: Text(
                    'Roll: ${student.rollId} | ${classes.firstWhere(
                      (c) => c.id == student.classId,
                      orElse: () => ClassRoom(id: '', name: 'Unknown'),
                    ).name}',
                  ),
                  trailing: Switch(
                    value: student.isActive,
                    onChanged: (val) {
                      context.read<StudentsNotifier>().toggleStudentStatus(
                        student.userId,
                      );
                    },
                    activeColor: Colors.green,
                  ),
                  onTap: () {
                    // Navigate to edit
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditStudentScreen()),
          );
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
