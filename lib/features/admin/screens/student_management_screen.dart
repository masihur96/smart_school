import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/screens/add_edit_student_screen.dart';
import 'package:smart_school/features/admin/screens/admin_pricing_plan_screen.dart';
import 'package:smart_school/features/admin/screens/student_detail_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';
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
              title: Text(AppLocalizations.of(context)!.studentManagement),
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
                    labelText: AppLocalizations.of(context)!.searchByName,
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
                          labelText: AppLocalizations.of(context)!.classLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(AppLocalizations.of(context)!.allClasses),
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
                          labelText: AppLocalizations.of(context)!.section,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(AppLocalizations.of(context)!.allSections),
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
                          labelText: AppLocalizations.of(context)!.status,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<bool?>(
                            value: null,
                            child: Text(AppLocalizations.of(context)!.allStatus),
                          ),
                          DropdownMenuItem<bool?>(
                            value: true,
                            child: Text(AppLocalizations.of(context)!.activeOnly),
                          ),
                          DropdownMenuItem<bool?>(
                            value: false,
                            child: Text(AppLocalizations.of(context)!.inactiveOnly),
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
                        Text(
                          AppLocalizations.of(context)!.total,
                          style: const TextStyle(
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
                  ? Center(child: Text(AppLocalizations.of(context)!.noStudentsFound))
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
                                leading: Hero(
                                  tag: 'student-avatar-${student.userId}',
                                  child: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.purple,
                                    backgroundImage: student.user?.avatar?.isNotEmpty == true
                                        ? NetworkImage(student.user!.avatar!)
                                        : null,
                                    child: student.user?.avatar?.isNotEmpty == true
                                        ? null
                                        : Text(
                                      student.user?.name.isNotEmpty == true
                                          ? student.user!.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
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
                                      final l10n = AppLocalizations.of(context)!;
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(l10n.deleteStudent),
                                          content: const Text(
                                            'Are you sure you want to delete this student?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: Text(l10n.cancel),
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
                                              child: Text(
                                                l10n.delete,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    final l10n = AppLocalizations.of(context)!;
                                    return <PopupMenuEntry<String>>[
                                      PopupMenuItem<String>(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.visibility,
                                              color: Colors.purple,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(l10n.viewDetails),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'notify',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.notifications_active_outlined,
                                              color: Colors.purple,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(l10n.sendNotification),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(l10n.edit),
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
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.delete,
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
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
                title: Text(AppLocalizations.of(context)!.limitReached),
                content: Text(
                  AppLocalizations.of(context)!.studentLimitReached(studentCount, maxStudents),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
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
                    child: Text(AppLocalizations.of(context)!.upgradePlan),
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
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.notifyStudent(student.user?.name ?? l10n.students)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: l10n.titleLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.messageLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty ||
                            messageController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.pleaseEnterTitleAndMessage),
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
                              SnackBar(
                                content: Text(l10n.notificationSentSuccessfully),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            isSending = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.failedToSendNotification),
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
                    : Text(l10n.send),
              ),
            ],
          );
        },
      ),
    );
  }
}
