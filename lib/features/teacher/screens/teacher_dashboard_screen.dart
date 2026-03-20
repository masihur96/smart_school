import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/screens/class_detail_screen.dart';
import 'package:smart_school/features/profile/presentation/views/profile_screen.dart';
import 'package:smart_school/models/school_models.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/teacher_dashboard_provider.dart';
import 'homework_management_screen.dart';
import 'mark_entry_screen.dart';
import 'teacher_attendance_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final dateString =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
      context.read<TeacherDashboardProvider>().fetchTodayClasses(dateString);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Teacher Dashboard';
      case 1:
        return 'Attendance';
      case 2:
        return 'Mark Entry';
      case 3:
        return 'Homework';
      default:
        return 'Teacher Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardOverview(context, user?.name ?? 'Teacher'),
          const TeacherAttendanceScreen(hideAppBar: true),
          const MarkEntryScreen(hideAppBar: true),
          const HomeworkManagementScreen(hideAppBar: true),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: 'Marks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Homework',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardOverview(BuildContext context, String name) {
    final provider = context.watch<TeacherDashboardProvider>();
    final classes = provider.todayClasses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context, name, classes.length),
          const SizedBox(height: 24),
          Text(
            'My Classes Today',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.error != null)
            Center(
              child: Text(
                'Error: ${provider.error}',
                style: TextStyle(color: Colors.red),
              ),
            )
          else if (classes.isEmpty)
            const Center(child: Text('No classes today.'))
          else
            ...classes.map(
              (c) => _buildClassTile(
               context:  context,
               className:  c.classEntity?.name ?? 'Class ${c.classId}',
              classRom:   c.classEntity!,
              subject:   c.subjectEntity?.name ?? 'Subject ${c.subjectId}',
              time:   '${c.startTime} - ${c.endTime}',
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            'Take Attendance',
            Icons.check_circle,
            Colors.green,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _buildActionCard(
            context,
            'Mark Entry',
            Icons.assignment_turned_in,
            Colors.blue,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          _buildActionCard(
            context,
            'Post Homework',
            Icons.assignment,
            Colors.orange,
            onTap: () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String name, int classCount) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $name!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'You have $classCount classes today.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassTile({
    required BuildContext context,
   required String className,
   required ClassRoom classRom,
   required String subject,
   required String time,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          classRom.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$subject | $time'),
        trailing: SizedBox(
          width: 80,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ClassDetailScreen(classRoom: classRom),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: EdgeInsets.zero,
            ),
            child: const Text('Enter'),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
