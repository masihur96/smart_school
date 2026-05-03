import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/super_admin/models/school_model.dart';
import 'package:smart_school/features/super_admin/providers/school_management_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/user_model.dart';

class SchoolManagementDetailsScreen extends StatefulWidget {
  final SuperAdminSchool school;

  const SchoolManagementDetailsScreen({super.key, required this.school});

  @override
  State<SchoolManagementDetailsScreen> createState() => _SchoolManagementDetailsScreenState();
}

class _SchoolManagementDetailsScreenState extends State<SchoolManagementDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final schoolId = widget.school.id!;
    context.read<SchoolManagementNotifier>().fetchSchoolMembers(schoolId: schoolId, role: 'teacher');
    context.read<SchoolManagementNotifier>().fetchSchoolMembers(schoolId: schoolId, role: 'student');
    context.read<SchoolManagementNotifier>().fetchSchoolMembers(schoolId: schoolId, role: 'admin');
    
    // Fetch classes and sections for resolution
    context.read<ClassSetupNotifier>().fetchClasses(schoolId);
    context.read<SectionSetupNotifier>().fetchSections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.school.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'School ID: ${widget.school.schoolId}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Teachers', icon: Icon(Icons.school_rounded)),
            Tab(text: 'Students', icon: Icon(Icons.people_rounded)),
            Tab(text: 'Admins', icon: Icon(Icons.admin_panel_settings_rounded)),
          ],
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UserListTab(role: 'teacher'),
          _UserListTab(role: 'student'),
          _UserListTab(role: 'admin'),
        ],
      ),
    );
  }
}

class _UserListTab extends StatelessWidget {
  final String role;

  const _UserListTab({required this.role});

  @override
  Widget build(BuildContext context) {
    return Consumer3<SchoolManagementNotifier, ClassSetupNotifier, SectionSetupNotifier>(
      builder: (context, notifier, classNotifier, sectionNotifier, child) {
        final List<User> users;
        final bool isLoading;

        if (role == 'teacher') {
          users = notifier.teachers;
          isLoading = notifier.isLoadingTeachers;
        } else if (role == 'student') {
          users = notifier.students;
          isLoading = notifier.isLoadingStudents;
        } else {
          users = notifier.admins;
          isLoading = notifier.isLoadingAdmins;
        }

        if (isLoading || classNotifier.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No ${role}s found',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // For Teachers and Students, group by Class
        if (role == 'teacher' || role == 'student') {
          final Map<String, List<User>> groupedUsers = {};
          for (var user in users) {
            final classId = user.classId ?? 'unassigned';
            if (!groupedUsers.containsKey(classId)) {
              groupedUsers[classId] = [];
            }
            groupedUsers[classId]!.add(user);
          }

          final sortedClassIds = groupedUsers.keys.toList();
          // Sort such that 'unassigned' is last
          sortedClassIds.sort((a, b) {
            if (a == 'unassigned') return 1;
            if (b == 'unassigned') return -1;
            return a.compareTo(b);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedClassIds.length,
            itemBuilder: (context, classIndex) {
              final classId = sortedClassIds[classIndex];
              final classUsers = groupedUsers[classId]!;
              final className = classId == 'unassigned'
                  ? 'Unassigned'
                  : classNotifier.classes.firstWhere((c) => c.id == classId, orElse: () => ClassRoom(id: '', name: 'Unknown Class', schoolId: '')).name;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.class_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          className,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${classUsers.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...classUsers.map((user) => _UserCard(
                    user: user,
                    className: className,
                    sectionName: user.sectionId != null 
                        ? sectionNotifier.sections.firstWhere((s) => s.id == user.sectionId, orElse: () => Section(id: '', name: 'N/A', classId: '')).name
                        : 'N/A',
                  )),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        }

        // For Admins, just a simple list
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _UserCard(user: user);
          },
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final String? className;
  final String? sectionName;

  const _UserCard({
    required this.user,
    this.className,
    this.sectionName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildInfoTag(Icons.person_outline, user.role.name.toUpperCase()),
                      if (className != null && className != 'Unassigned')
                        _buildInfoTag(Icons.class_outlined, className!),
                      if (sectionName != null && sectionName != 'N/A')
                        _buildInfoTag(Icons.grid_view_rounded, 'Section: $sectionName'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (user.isActive ?? true) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (user.isActive ?? true) ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: (user.isActive ?? true) ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
