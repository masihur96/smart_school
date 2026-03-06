import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teacher/providers/attendance_provider.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
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
                TextButton(onPressed: () => context.push('/student/notices'), child: const Text('View Notices')),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionTile(context, 'Weekly Routine', Icons.calendar_month, Colors.purple, onTap: () => context.push('/student/routine')),
            _buildActionTile(context, 'Homework', Icons.assignment, Colors.orange, onTap: () => context.push('/student/homework')),
            _buildActionTile(context, 'Attendance History', Icons.history, Colors.blue, onTap: () => context.push('/student/attendance')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final attendanceRecords = ref.watch(attendanceProvider).where((r) => r.studentId == currentUser?.id).toList();
    final totalDays = attendanceRecords.length;
    final presentDays = attendanceRecords.where((r) => r.isPresent).length;
    final percentage = totalDays == 0 ? 0.0 : presentDays / totalDays;

    return InkWell(
      onTap: () => context.push('/student/attendance'),
      child: Card(
        elevation: 0,
        color: Colors.green.withOpacity(0.1),
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
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
