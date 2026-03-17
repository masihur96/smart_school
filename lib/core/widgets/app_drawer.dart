import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../models/user_model.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>();
    final user = authState.user;

    if (user == null) return const SizedBox.shrink();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.name),
            accountEmail: Text(user.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name[0],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            decoration: BoxDecoration(color: _getRoleColor(user.role)),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  Icons.person_outline,
                  'My Profile',
                  () => context.push('/profile'),
                  context,
                ),
                const Divider(),
                if (user.role == UserRole.admin) ..._buildAdminItems(context),
                if (user.role == UserRole.teacher)
                  ..._buildTeacherItems(context),
                if (user.role == UserRole.student)
                  ..._buildStudentItems(context),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<AuthNotifier>().logout();
              context.go('/login');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.teacher:
        return Colors.blue;
      case UserRole.student:
        return Colors.green;
    }
  }

  List<Widget> _buildAdminItems(BuildContext context) {
    return [
      _buildDrawerItem(
        Icons.dashboard,
        'Dashboard',
        () => context.go('/admin'),
        context,
      ),
      _buildDrawerItem(
        Icons.people,
        'Students',
        () => context.go('/admin/students'),
        context,
      ),
      _buildDrawerItem(
        Icons.person,
        'Teachers',
        () => context.go('/admin/teachers'),
        context,
      ),
      _buildDrawerItem(
        Icons.class_,
        'Class & Setup',
        () => context.go('/admin/setup'),
        context,
      ),
      _buildDrawerItem(
        Icons.event_note,
        'Routine',
        () => context.go('/admin/routine'),
        context,
      ),
      _buildDrawerItem(
        Icons.announcement,
        'Notices',
        () => context.go('/admin/notices'),
        context,
      ),
      _buildDrawerItem(
        Icons.assignment_turned_in,
        'Exams',
        () => context.go('/admin/exams'),
        context,
      ),
      _buildDrawerItem(Icons.settings, 'Settings', () {}, context),
    ];
  }

  List<Widget> _buildTeacherItems(BuildContext context) {
    return [
      _buildDrawerItem(
        Icons.dashboard,
        'Dashboard',
        () => context.go('/teacher'),
        context,
      ),
      _buildDrawerItem(
        Icons.check_circle,
        'Attendance',
        () => context.go('/teacher/attendance'),
        context,
      ),
      _buildDrawerItem(
        Icons.assignment,
        'Homework',
        () => context.go('/teacher/homework'),
        context,
      ),
      _buildDrawerItem(
        Icons.grade,
        'Mark Entry',
        () => context.go('/teacher/marks'),
        context,
      ),
      _buildDrawerItem(Icons.calendar_today, 'Routine', () {}, context),
    ];
  }

  List<Widget> _buildStudentItems(BuildContext context) {
    return [
      _buildDrawerItem(
        Icons.dashboard,
        'Dashboard',
        () => context.go('/student'),
        context,
      ),
      _buildDrawerItem(
        Icons.check_circle,
        'Attendance',
        () => context.go('/student/attendance'),
        context,
      ),
      _buildDrawerItem(
        Icons.assignment,
        'Homework',
        () => context.go('/student/homework'),
        context,
      ),
      _buildDrawerItem(
        Icons.calendar_month,
        'Routine',
        () => context.go('/student/routine'),
        context,
      ),
      _buildDrawerItem(
        Icons.notifications,
        'Notices',
        () => context.go('/student/notices'),
        context,
      ),
      _buildDrawerItem(
        Icons.assessment,
        'Results',
        () => context.go('/student/results'),
        context,
      ),
    ];
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
