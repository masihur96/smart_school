import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/models/school_models.dart';
import '../../teacher/providers/attendance_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

class StudentAttendanceScreen extends StatelessWidget {
  final bool hideAppBar;
  const StudentAttendanceScreen({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthNotifier>().user;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final attendanceRecords = context.watch<AttendanceNotifier>().state.where((r) => r.studentId == currentUser.id).toList();
    attendanceRecords.sort((a, b) => b.date.compareTo(a.date));

    final totalDays = attendanceRecords.length;
    final presentDays = attendanceRecords.where((r) => r.status == AttendanceStatus.present).length;
    final leaveDays = attendanceRecords.where((r) => r.status == AttendanceStatus.leave).length;
    final absentDays = attendanceRecords.where((r) => r.status == AttendanceStatus.absent).length;
    final attendancePercentage = totalDays == 0 ? 0.0 : presentDays / totalDays;

    return Scaffold(
      appBar: hideAppBar ? null : AppBar(
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
                      _buildStatItem('Leave', leaveDays.toString(), color: Colors.orange),
                      _buildStatItem('Absent', absentDays.toString(), color: Colors.red),
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
                  final isPresent = record.status == AttendanceStatus.present;
                  final isLeave = record.status == AttendanceStatus.leave;
                  
                  return ListTile(
                    leading: Icon(
                      isPresent ? Icons.check_circle : (isLeave ? Icons.info : Icons.cancel), 
                      color: isPresent ? Colors.green : (isLeave ? Colors.orange : Colors.red),
                    ),
                    title: Text(DateFormat('EEEE, MMM d, yyyy').format(record.date)),
                    trailing: Text(
                      record.status.name.substring(0, 1).toUpperCase() + record.status.name.substring(1), 
                      style: TextStyle(
                        color: isPresent ? Colors.green : (isLeave ? Colors.orange : Colors.red),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
