import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_school/features/admin/screens/add_edit_student_screen.dart';
import '../providers/student_provider.dart';
import '../providers/setup_provider.dart';
import '../../auth/providers/auth_provider.dart';
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
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      final schoolId = user?.schoolId ?? '';
      
      if (schoolId.isNotEmpty) {
        context.read<ClassSetupNotifier>().fetchClasses(schoolId);
      }
      context.read<SectionSetupNotifier>().fetchSections();
      context.read<StudentsNotifier>().fetchStudents();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final notifier = context.read<StudentsNotifier>();
      if (!notifier.isLoadingMore && notifier.hasMore) {
        notifier.fetchStudents(
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
          loadMore: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsNotifier = context.watch<StudentsNotifier>();
    final students = studentsNotifier.students;
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;

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
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ...classes.map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    value: _selectedClassId,
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
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Sections'),
                      ),
                      ...sections
                          .where((s) => s.classId == _selectedClassId)
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          ),
                    ],
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
            child: studentsNotifier.isLoading && students.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                    ? const Center(child: Text('No students found.'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: students.length + (studentsNotifier.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                if (index == students.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
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
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditStudentScreen(student: student),
                          ),
                        ).then((_) {
                          context.read<StudentsNotifier>().fetchStudents(
                             classId: _selectedClassId, 
                             sectionId: _selectedSectionId,
                          );
                        });
                      } else if (value == 'status') {
                        context.read<StudentsNotifier>().toggleStudentStatus(
                          student.userId,
                        );
                      } else if (value == 'delete') {
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
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(student.isActive ? Icons.block : Icons.check_circle, 
                                 color: student.isActive ? Colors.orange : Colors.green),
                            const SizedBox(width: 8),
                            Text(student.isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
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
            MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
          ).then((_) {
            context.read<StudentsNotifier>().fetchStudents(
                  classId: _selectedClassId,
                  sectionId: _selectedSectionId,
                );
          });
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
