import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/admin/screens/add_edit_teacher_screen.dart';
import 'package:smart_school/features/admin/screens/admin_pricing_plan_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart' hide Teacher;
import 'package:smart_school/models/teacher_model.dart';

import '../providers/setup_provider.dart';
import '../providers/teacher_provider.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
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
      final authNotifier = context.read<AuthNotifier>();
      final schoolId = authNotifier.user?.schoolId;

      _fetchTeachers();
      if (schoolId != null) {
        context.read<ClassSetupNotifier>().fetchClasses(schoolId);
        context.read<SectionSetupNotifier>().fetchSections();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TeachersNotifier>().fetchTeachers(
        loadMore: true,
        classId: _selectedClass,
        sectionId: _selectedSection,
        isActive: _selectedStatus == 'Active'
            ? true
            : (_selectedStatus == 'Inactive' ? false : null),
      );
    }
  }

  void _fetchTeachers() {
    context.read<TeachersNotifier>().fetchTeachers(
      classId: _selectedClass,
      sectionId: _selectedSection,
      isActive: _selectedStatus == 'Active'
          ? true
          : (_selectedStatus == 'Inactive' ? false : null),
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
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
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
                // Row(
                //   children: [
                //     Expanded(
                //       child: DropdownButtonFormField<String>(
                //         decoration: InputDecoration(
                //           labelText: 'Class',
                //           contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                //         ),
                //         items: [
                //           const DropdownMenuItem(value: null, child: Text('All')),
                //           ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                //         ],
                //         onChanged: (val) {
                //           setState(() {
                //             _selectedClass = val;
                //             _selectedSection = null; // Reset section when class changes
                //           });
                //           _fetchTeachers();
                //         },
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     Expanded(
                //       child: DropdownButtonFormField<String>(
                //         decoration: InputDecoration(
                //           labelText: 'Section',
                //           contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                //         ),
                //         value: _selectedSection,
                //         items: [
                //           const DropdownMenuItem(value: null, child: Text('All')),
                //           ...sections
                //               .where((s) => s.classId == _selectedClass)
                //               .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                //         ],
                //         onChanged: (val) {
                //           setState(() => _selectedSection = val);
                //           _fetchTeachers();
                //         },
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  )
                : teachers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No teachers found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
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
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.purple,
                            ),
                          ),
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
                                    colors: [
                                      Colors.purple.shade300,
                                      Colors.purple.shade600,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
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
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.green.shade50
                                                : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: isActive
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      teacher.designation.isEmpty
                                          ? 'Teacher'
                                          : teacher.designation,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 14,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user?.email ?? '',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'view') {
                                    _showTeacherDetails(context, teacher);
                                  } else if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddEditTeacherScreen(
                                          teacher: teacher,
                                        ),
                                      ),
                                    ).then((_) => _fetchTeachers());
                                  } else if (value == 'status') {
                                    await context
                                        .read<TeachersNotifier>()
                                        .toggleTeacherStatus(teacher.userId);
                                  } else if (value == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Teacher'),
                                        content: const Text(
                                          'Are you sure you want to delete this teacher?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await context
                                          .read<TeachersNotifier>()
                                          .deleteTeacher(teacher.userId);
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('View Profile'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Edit Teacher'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'status',
                                    child: Row(
                                      children: [
                                        Icon(
                                          isActive
                                              ? Icons.toggle_off
                                              : Icons.toggle_on,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isActive ? 'Deactivate' : 'Activate',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
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
          final studentCount = context.watch<StudentsNotifier>().totalCount;
          final authState = context.watch<AuthNotifier>();

          final maxStudents =
              authState.adminSubscription?.pricingPlan?.maxStudents;

          if (maxStudents != null && studentCount >= maxStudents) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Limit Reached"),
                content: Text(
                  "You have reached your student limit ($studentCount / $maxStudents).\n\nUpgrade your plan to add more students.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPricingPlanScreen(),
                        ),
                      );
                    },
                    child: const Text("Upgrade Plan"),
                  ),
                ],
              ),
            );
            return;
          }

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

  void _showTeacherDetails(BuildContext context, Teacher teacher) {
    final user = teacher.user;
    final classes = context.read<ClassSetupNotifier>().classes;
    final sections = context.read<SectionSetupNotifier>().sections;

    final className = classes
        .firstWhere(
          (c) => c.id == teacher.classId,
          orElse: () => ClassRoom(id: '', name: 'N/A', schoolId: ''),
        )
        .name;
    final sectionName = sections
        .firstWhere(
          (s) => s.id == teacher.sectionId,
          orElse: () => Section(id: '', name: 'N/A', classId: ''),
        )
        .name;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          teacher.designation,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Contact Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildDetailItem(
                Icons.email_outlined,
                'Email',
                user?.email ?? 'N/A',
              ),
              _buildDetailItem(
                Icons.phone_outlined,
                'Phone',
                user?.phone ?? 'N/A',
              ),
              const SizedBox(height: 20),
              const Text(
                'Academic Assignment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildDetailItem(
                Icons.class_outlined,
                'Assigned Class',
                className,
              ),
              _buildDetailItem(
                Icons.groups_outlined,
                'Assigned Section',
                sectionName,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple.shade300),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
