import 'package:flutter/material.dart';
import 'package:teacher_app/core/theme.dart';
import 'package:teacher_app/data/mock_data/mock_data.dart';

class OwnAttendanceScreen extends StatelessWidget {
  const OwnAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Present', '22', Colors.white),
                _buildStat('Absent', '2', Colors.white70),
                _buildStat('Leave', '1', Colors.white70),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: MockData.teacherAttendance.length,
              itemBuilder: (context, index) {
                final record = MockData.teacherAttendance[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: record['status'] == 'Present' 
                          ? AppColors.success.withOpacity(0.1) 
                          : AppColors.error.withOpacity(0.1),
                      child: Icon(
                        record['status'] == 'Present' ? Icons.check : Icons.close,
                        color: record['status'] == 'Present' ? AppColors.success : AppColors.error,
                      ),
                    ),
                    title: Text(record['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      record['status'],
                      style: TextStyle(
                        color: record['status'] == 'Present' ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Note: Attendance cannot be edited or deleted.',
              style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }
}
