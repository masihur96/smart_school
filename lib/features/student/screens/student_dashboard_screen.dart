import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:smart_school/models/school_models.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teacher/providers/attendance_provider.dart';
import 'student_attendance_screen.dart';
import 'student_result_screen.dart';
import 'student_homework_screen.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Student Dashboard';
      case 1:
        return 'My Attendance';
      case 2:
        return 'My Results';
      case 3:
        return 'My Homework';
      default:
        return 'Student Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardOverview(context, ref),
          const StudentAttendanceScreen(hideAppBar: true),
          const StudentResultScreen(hideAppBar: true),
          const StudentHomeworkScreen(hideAppBar: true),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Results'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Homework'),
        ],
      ),
    );
  }

  Widget _buildDashboardOverview(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceCard(context, ref),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => setState(() => _selectedIndex = 2), child: const Text('View Results')),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionTile(context, 'Weekly Routine', Icons.calendar_month, Colors.purple, onTap: () {
            // Routine is not in bottom nav, push usually
            // but we can decide to keep it as push
          }),
          _buildActionTile(context, 'My Homework', Icons.assignment, Colors.orange, onTap: () => setState(() => _selectedIndex = 3)),
          _buildActionTile(context, 'Attendance History', Icons.history, Colors.blue, onTap: () => setState(() => _selectedIndex = 1)),
          _buildActionTile(context, 'My Results', Icons.emoji_events, Colors.green, onTap: () => setState(() => _selectedIndex = 2)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final attendanceRecords = ref.watch(attendanceProvider).where((r) => r.studentId == currentUser?.id).toList();
    final totalDays = attendanceRecords.length;
    final presentDays = attendanceRecords.where((r) => r.status == AttendanceStatus.present).length;
    final percentage = totalDays == 0 ? 0.0 : presentDays / totalDays;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = 1),
      child: Card(
        elevation: 0,
        color: Colors.green.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 40.0,
                lineWidth: 8.0,
                percent: percentage,
                center: Text("${(percentage * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                progressColor: Colors.green,
                backgroundColor: Colors.white,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attendance Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('You were present $presentDays out of $totalDays days.', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
