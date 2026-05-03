import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/super_admin/models/school_model.dart';
import 'package:smart_school/features/super_admin/providers/school_management_provider.dart';
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
    _fetchData();
  }

  void _fetchData() {
    final notifier = context.read<SchoolManagementNotifier>();
    notifier.fetchSchoolMembers(schoolId: widget.school.id!, role: 'teacher');
    notifier.fetchSchoolMembers(schoolId: widget.school.id!, role: 'student');
    notifier.fetchSchoolMembers(schoolId: widget.school.id!, role: 'admin');
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
    return Consumer<SchoolManagementNotifier>(
      builder: (context, notifier, child) {
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

        if (isLoading) {
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

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            if (user.phone != null && user.phone!.isNotEmpty)
              Text(user.phone!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Container(
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
      ),
    );
  }
}
