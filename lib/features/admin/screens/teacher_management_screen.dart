import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_school/features/admin/screens/add_edit_teacher_screen.dart';
import '../providers/teacher_provider.dart';
import '../providers/setup_provider.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTeachers();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<TeachersNotifier>().fetchTeachers(
        loadMore: true,
        classId: _selectedClass,
        sectionId: _selectedSection,
        isActive: _selectedStatus == 'Active' ? true : (_selectedStatus == 'Inactive' ? false : null),
      );
    }
  }

  void _fetchTeachers() {
    context.read<TeachersNotifier>().fetchTeachers(
      classId: _selectedClass,
      sectionId: _selectedSection,
      isActive: _selectedStatus == 'Active' ? true : (_selectedStatus == 'Inactive' ? false : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teachers = context.watch<TeachersNotifier>().teachers;
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;
    final isLoading = context.watch<TeachersNotifier>().isLoading;
    final isLoadingMore = context.watch<TeachersNotifier>().isLoadingMore;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Teacher Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Class',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        value: _selectedClass,
                        items: [
                          const DropdownMenuItem(value: '', child: Text('All Classes')),
                          ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedClass = val == '' ? null : val;
                            _selectedSection = null;
                          });
                          _fetchTeachers();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Section',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        value: _selectedSection,
                        items: [
                          const DropdownMenuItem(value: '', child: Text('All Sections')),
                          ...sections
                              .where((s) => s.classId == _selectedClass)
                              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedSection = val == '' ? null : val);
                          _fetchTeachers();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  value: _selectedStatus,
                  items: ['All', 'Active', 'Inactive']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    _fetchTeachers();
                  },
                ),
              ],
            ),
          ),
          
          // Teachers List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                : teachers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No teachers found', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: teachers.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == teachers.length) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator(color: Colors.purple)),
                            );
                          }

                          final teacher = teachers[index];
                          final user = teacher.user;
                          final isActive = teacher.isActive;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.purple.shade300, Colors.purple.shade600],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 30),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              user?.name ?? 'No Name',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isActive ? 'Active' : 'Inactive',
                                                style: TextStyle(
                                                  color: isActive ? Colors.green : Colors.red,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          teacher.designation.isEmpty ? 'Teacher' : teacher.designation,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade400),
                                            const SizedBox(width: 4),
                                            Text(user?.email ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      if (value == 'status') {
                                        await context.read<TeachersNotifier>().toggleTeacherStatus(teacher.userId);
                                      } else if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Teacher'),
                                            content: const Text('Are you sure you want to delete this teacher?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await context.read<TeachersNotifier>().deleteTeacher(teacher.userId);
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'status',
                                        child: Row(
                                          children: [
                                            Icon(isActive ? Icons.toggle_off : Icons.toggle_on, color: Colors.blue),
                                            const SizedBox(width: 8),
                                            Text(isActive ? 'Deactivate' : 'Activate'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: Colors.red),
                                            const SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
            MaterialPageRoute(builder: (_) => const AddEditTeacherScreen()),
          ).then((_) => _fetchTeachers());
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
