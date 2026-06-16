import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/admin/screens/add_edit_teacher_screen.dart';
import 'package:smart_school/features/admin/screens/admin_pricing_plan_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/school_models.dart' hide Teacher;
import 'package:smart_school/models/teacher_model.dart';
import 'package:smart_school/services/notification_service.dart';

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

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teacherManagementTitle),
        backgroundColor: AppColors.primaryAdmin,
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // color: Colors.white,
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
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.purple.withOpacity(0.1),
                                backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty
                                    ? NetworkImage(user.avatar!)
                                    : null,
                                child: user?.avatar == null || user!.avatar!.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.purple,
                                        size: 30,
                                      )
                                    : null,
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
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.email_outlined, size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            user?.email ?? '',
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (teacher.embeddedClasses.isNotEmpty) ...
                                      [
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.class_outlined, size: 14, color: Colors.purple.shade300),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                teacher.embeddedClasses.map((c) => c.name).join(', '),
                                                style: TextStyle(fontSize: 12, color: Colors.purple.shade400),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    if (teacher.embeddedSections.isNotEmpty) ...
                                      [
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.groups_outlined, size: 14, color: Colors.teal.shade300),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                teacher.embeddedSections.map((s) => s.name).join(', '),
                                                style: TextStyle(fontSize: 12, color: Colors.teal.shade400),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'view') {
                                    _showTeacherDetails(context, teacher);
                                  } else if (value == 'notify') {
                                    _showNotificationDialog(context, teacher);
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
                                    final l10n = AppLocalizations.of(context)!;
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(l10n.deleteTeacher),
                                        content: Text(
                                          'Are you sure you want to delete this teacher?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text(l10n.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: Text(
                                              l10n.delete,
                                              style: const TextStyle(
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
                                itemBuilder: (context) {
                                  final l10n = AppLocalizations.of(context)!;
                                  return [
                                    PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.visibility_outlined,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(l10n.viewProfile),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
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
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(l10n.editTeacher),
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
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(l10n.delete),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
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

    // Use embedded classes/sections from the API response first;
    // fall back to provider lookups if not available.
    final localClasses = context.read<ClassSetupNotifier>().classes;
    final localSections = context.read<SectionSetupNotifier>().sections;

    final classNames = teacher.embeddedClasses.isNotEmpty
        ? teacher.embeddedClasses.map((c) => c.name).join(', ')
        : localClasses
              .firstWhere(
                (c) => c.id == teacher.classId,
                orElse: () => ClassRoom(id: '', name: 'N/A', schoolId: ''),
              )
              .name;

    final sectionNames = teacher.embeddedSections.isNotEmpty
        ? teacher.embeddedSections.map((s) => s.name).join(', ')
        : localSections
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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty
                        ? NetworkImage(user.avatar!)
                        : null,
                    child: user?.avatar == null || user!.avatar!.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.purple,
                            size: 35,
                          )
                        : null,
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
                actionIcon: Icons.send,
                onTap: user?.email != null
                    ? () => _launchUrl('mailto:${user!.email}')
                    : null,
              ),
              _buildDetailItem(
                Icons.phone_outlined,
                'Phone',
                user?.phone ?? 'N/A',
                actionIcon: Icons.call,
                onTap: user?.phone != null
                    ? () => _launchUrl('tel:${user!.phone}')
                    : null,
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
                classNames,
              ),
              _buildDetailItem(
                Icons.groups_outlined,
                'Assigned Section',
                sectionNames,
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value, {
    IconData? actionIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
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
          ),
          if (actionIcon != null && onTap != null)
            Material(
              color: Colors.purple.shade50,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    actionIcon,
                    size: 18,
                    color: Colors.purple.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, Teacher teacher) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.notifyTeacher(teacher.user?.name ?? l10n.teacher)),
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
                            receiverUuid: teacher.user?.id ?? teacher.userId,
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
