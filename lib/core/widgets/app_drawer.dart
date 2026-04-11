import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smart_school/features/admin/screens/exam_management_screen.dart';
import 'package:smart_school/features/admin/screens/notice_management_screen.dart';
import 'package:smart_school/features/admin/screens/routine_management_screen.dart';
import 'package:smart_school/features/admin/screens/setup_screen.dart';
import 'package:smart_school/features/admin/screens/student_management_screen.dart';
import 'package:smart_school/features/admin/screens/teacher_management_screen.dart';
import 'package:smart_school/features/auth/presntation/views/login_screen.dart';
import 'package:smart_school/features/setting_management_screen.dart';
import 'package:smart_school/features/student/screens/student_attendance_screen.dart';
import 'package:smart_school/features/student/screens/student_dashboard_screen.dart';
import 'package:smart_school/features/student/screens/student_homework_screen.dart';
import 'package:smart_school/features/student/screens/student_notice_screen.dart';
import 'package:smart_school/features/student/screens/student_result_screen.dart';
import 'package:smart_school/features/student/screens/student_routine_screen.dart';
import 'package:smart_school/features/teacher/screens/homework_management_screen.dart';
import 'package:smart_school/features/teacher/screens/mark_entry_screen.dart';
import 'package:smart_school/features/teacher/screens/teacher_attendance_screen.dart';
import 'package:smart_school/features/teacher/screens/teacher_dashboard_screen.dart';
import 'package:smart_school/features/teacher/screens/teacher_routine_screen.dart';

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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
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
      case UserRole.superadmin:
        return Colors.amber;
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  List<Widget> _buildAdminItems(BuildContext context) {
    return [
      _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboardScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.people, 'Students', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudentManagementScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.person, 'Teachers', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TeacherManagementScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.class_, 'Class & Setup', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SetupScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.event_note, 'Routine', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RoutineManagementScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.announcement, 'Notices', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoticeManagementScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.assignment_turned_in, 'Exams', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExamManagementScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.settings, 'Settings', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingManagementScreen()),
        );
      }, context),
    ];
  }

  List<Widget> _buildTeacherItems(BuildContext context) {
    return [
      _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TeacherDashboardScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.check_circle, 'Attendance', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TeacherAttendanceScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.assignment, 'Homework', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HomeworkManagementScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.grade, 'Mark Entry', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MarkEntryScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.calendar_today, 'Routine', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeacherRoutineScreen()),
        );
      }, context),
    ];
  }

  List<Widget> _buildStudentItems(BuildContext context) {
    return [
      _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudentDashboardScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.check_circle, 'Attendance', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudentAttendanceScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.assignment, 'Homework', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudentHomeworkScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.calendar_month, 'Routine', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudentRoutineScreen()),
        );
      }, context),
      _buildDrawerItem(Icons.notifications, 'Notices', () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentNoticeScreen(isFromDrawer: true),
          ),
        );
      }, context),
      _buildDrawerItem(Icons.assessment, 'Results', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudentResultScreen()),
        );
      }, context),
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
