import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/screens/add_edit_student_screen.dart';
import 'package:smart_school/features/admin/screens/admin_pricing_plan_screen.dart';
import 'package:smart_school/features/admin/screens/student_detail_screen.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:smart_school/services/notification_service.dart';

import '../../../models/school_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';

class StudentManagementScreen extends StatefulWidget {
  final bool hideAppBar;
  const StudentManagementScreen({super.key, this.hideAppBar = false});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  bool? _selectedStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = context.read<StudentsNotifier>();
      if (!notifier.isLoadingMore && notifier.hasMore) {
        notifier.fetchStudents(
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
          isActive: _selectedStatus,
          search: _searchQuery.isEmpty ? null : _searchQuery,
          loadMore: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<StudentsNotifier>().fetchStudents(
      classId: _selectedClassId,
      sectionId: _selectedSectionId,
      isActive: _selectedStatus,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsNotifier = context.watch<StudentsNotifier>();
    final students = List.of(studentsNotifier.students)
      ..sort((a, b) {
        final aRoll = int.tryParse(a.rollId);
        final bRoll = int.tryParse(b.rollId);
        if (aRoll != null && bRoll != null) return aRoll.compareTo(bRoll);
        return a.rollId.compareTo(b.rollId);
      });
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('Student Management'),
              backgroundColor: AppColors.primaryAdmin,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context.push('/admin/students/add'),
                ),
              ],
            ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 500),
                      _applyFilters,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
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
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
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
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem<bool?>(
                            value: null,
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem<bool?>(
                            value: true,
                            child: Text('Active Only'),
                          ),
                          DropdownMenuItem<bool?>(
                            value: false,
                            child: Text('Inactive Only'),
                          ),
                        ],
                        value: _selectedStatus,
                        onChanged: (val) {
                          setState(() => _selectedStatus = val);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${studentsNotifier.totalCount}',
                          style: const TextStyle(
                            fontSize: 16,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: studentsNotifier.isLoading && students.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : students.isEmpty
                  ? const Center(child: Text('No students found.'))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          students.length + (studentsNotifier.hasMore ? 1 : 0),
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
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),

                          child: Stack(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple.shade300,
                                        Colors.purple.shade600,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Hero(
                                      tag: 'student-avatar-${student.userId}',
                                      child: Text(
                                        student.user?.name[0] ?? '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student.user?.name ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Roll: ${student.rollId}'),
                                    Text(
                                      classes
                                          .firstWhere(
                                            (c) => c.id == student.classId,
                                            orElse: () => ClassRoom(
                                              id: '',
                                              name: 'Unknown',
                                            ),
                                          )
                                          .name,
                                    ),
                                  ],
                                ),

                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    if (value == 'view') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentDetailScreen(
                                            student: student,
                                          ),
                                        ),
                                      ).then((_) => _applyFilters());
                                    } else if (value == 'notify') {
                                      _showNotificationDialog(context, student);
                                    } else if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditStudentScreen(
                                            student: student,
                                          ),
                                        ),
                                      ).then((_) {
                                        _applyFilters();
                                      });
                                    } else if (value == 'status') {
                                      context
                                          .read<StudentsNotifier>()
                                          .toggleStudentStatus(student.userId);
                                    } else if (value == 'delete') {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Student'),
                                          content: const Text(
                                            'Are you sure you want to delete this student?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                context
                                                    .read<StudentsNotifier>()
                                                    .deleteStudent(
                                                      student.userId,
                                                    );
                                                Navigator.pop(ctx);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.visibility,
                                                color: Colors.purple,
                                              ),
                                              SizedBox(width: 8),
                                              Text('View Details'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'notify',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .notifications_active_outlined,
                                                color: Colors.purple,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Send Notification'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'status',
                                          child: Row(
                                            children: [
                                              Icon(
                                                student.isActive
                                                    ? Icons.block
                                                    : Icons.check_circle,
                                                color: student.isActive
                                                    ? Colors.orange
                                                    : Colors.green,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                student.isActive
                                                    ? 'Deactivate'
                                                    : 'Activate',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                ),
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: student.isActive
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    student.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: student.isActive
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final studentCount = context.read<StudentsNotifier>().totalCount;

          final authState = context.read<AuthNotifier>();

          final maxStudents =
              authState.adminSubscription?.pricingPlan?.maxStudents;

          if (maxStudents != null && studentCount >= maxStudents) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Limit Reached"),
                content: Text(
                  "You have reached your student limit "
                  "($studentCount / $maxStudents).\n\n"
                  "Upgrade your plan to add more students.",
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
            MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
          ).then((_) {
            _applyFilters();
          });
        },

        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, Student student) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Notify ${student.user?.name ?? 'Student'}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty ||
                            messageController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter title and message'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          isSending = true;
                        });

                        try {
                          await NotificationService().sendNotification(
                            receiverUuid: student.user?.id ?? student.userId,
                            title: titleController.text.trim(),
                            message: messageController.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notification sent successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            isSending = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to send notification'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send'),
              ),
            ],
          );
        },
      ),
    );
  }
}
