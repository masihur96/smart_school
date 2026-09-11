import 'package:flutter/material.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/data/mock_data/mock_data.dart';

class OwnAttendanceScreen extends StatelessWidget {
  const OwnAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.myAttendance)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(AppLocalizations.of(context)!.present, '22', Colors.white),
                _buildStat(AppLocalizations.of(context)!.absent, '2', Colors.white70),
                _buildStat(AppLocalizations.of(context)!.leave, '1', Colors.white70),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: record['status'] == AppLocalizations.of(context)!.present
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      child: Icon(
                        record['status'] == AppLocalizations.of(context)!.present
                            ? Icons.check
                            : Icons.close,
                        color: record['status'] == AppLocalizations.of(context)!.present
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    title: Text(
                      record['date'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      record['status'],
                      style: TextStyle(
                        color: record['status'] == AppLocalizations.of(context)!.present
                            ? AppColors.success
                            : AppColors.error,
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
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }
}
