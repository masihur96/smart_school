import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_school/features/admin/screens/add_edit_student_screen.dart';
import '../providers/student_provider.dart';
import '../../../services/database_service.dart';
import '../../../models/school_models.dart';
import 'package:flutter/material.dart';

class StudentManagementScreen extends StatefulWidget {
  final bool hideAppBar;
  const StudentManagementScreen({super.key, this.hideAppBar = false});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentsNotifier>().fetchStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentsNotifier = context.watch<StudentsNotifier>();
    final students = studentsNotifier.students;
    final dbService = context.watch<DatabaseService>();
    final classes = dbService.classes;
    final sections = dbService.sections;

    return Scaffold(
      appBar: widget.hideAppBar
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
                    onChanged: (val) {
                      setState(() {
                         _selectedClassId = val;
                         _selectedSectionId = null; // reset section
                      });
                      context.read<StudentsNotifier>().fetchStudents(
                         classId: _selectedClassId, 
                         sectionId: _selectedSectionId,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: sections
                        .where((s) => s.classId == _selectedClassId)
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    value: _selectedSectionId,
                    onChanged: (val) {
                       setState(() => _selectedSectionId = val);
                       context.read<StudentsNotifier>().fetchStudents(
                         classId: _selectedClassId, 
                         sectionId: _selectedSectionId,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: studentsNotifier.isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: student.isActive,
                        onChanged: (val) {
                          context.read<StudentsNotifier>().toggleStudentStatus(
                            student.userId,
                          );
                        },
                        activeColor: Colors.green,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Student'),
                              content: const Text('Are you sure you want to delete this student?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<StudentsNotifier>().deleteStudent(student.userId);
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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
