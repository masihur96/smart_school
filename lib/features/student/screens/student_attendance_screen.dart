import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../teacher/providers/attendance_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final attendanceRecords = ref.watch(attendanceProvider).where((r) => r.studentId == currentUser.id).toList();
    attendanceRecords.sort((a, b) => b.date.compareTo(a.date));

    final totalDays = attendanceRecords.length;
    final presentDays = attendanceRecords.where((r) => r.isPresent).length;
    final attendancePercentage = totalDays == 0 ? 0.0 : presentDays / totalDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              color: Colors.green.withOpacity(0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CircularPercentIndicator(
                    radius: 60.0,
                    lineWidth: 10.0,
                    percent: attendancePercentage,
                    center: Text("${(attendancePercentage * 100).toStringAsFixed(1)}%", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    progressColor: Colors.green,
                    backgroundColor: Colors.green.withOpacity(0.2),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem('Total Days', totalDays.toString()),
                      _buildStatItem('Present', presentDays.toString(), color: Colors.green),
                      _buildStatItem('Absent', (totalDays - presentDays).toString(), color: Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Attendance Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            if (attendanceRecords.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No attendance records found.')))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = attendanceRecords[index];
                  return ListTile(
                    leading: Icon(record.isPresent ? Icons.check_circle : Icons.cancel, 
                                 color: record.isPresent ? Colors.green : Colors.red),
                    title: Text(DateFormat('EEEE, MMM d, yyyy').format(record.date)),
                    trailing: Text(record.isPresent ? 'Present' : 'Absent', 
                                   style: TextStyle(color: record.isPresent ? Colors.green : Colors.red)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        ],
      ),
    );
  }
}
