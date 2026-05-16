import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/models/school_models.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/student_attendance_provider.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final bool hideAppBar;
  const StudentAttendanceScreen({super.key, this.hideAppBar = false});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime? _selectedDate;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentAttendanceNotifier>().fetchAttendance();
    });
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthNotifier>().user;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final attendanceNotifier = context.watch<StudentAttendanceNotifier>();
    final attendanceRecords = attendanceNotifier.attendanceRecords;
    final isLoading = attendanceNotifier.isLoading;
    final error = attendanceNotifier.error;

    // Extract subjects for filtering
    final subjects = <String, String>{};
    for (var r in attendanceRecords) {
      if (r.subjectInfo != null && r.subjectId != null) {
        subjects[r.subjectId!] = r.subjectInfo!.name;
      }
    }

    // Apply filters
    var filteredRecords = attendanceRecords.where((r) {
      bool matchDate = true;
      bool matchSubject = true;

      if (_selectedDate != null) {
        matchDate =
            r.date.year == _selectedDate!.year &&
            r.date.month == _selectedDate!.month &&
            r.date.day == _selectedDate!.day;
      }

      if (_selectedSubjectId != null && _selectedSubjectId != 'all') {
        matchSubject = r.subjectId == _selectedSubjectId;
      }

      return matchDate && matchSubject;
    }).toList();

    // Sorting records by date (most recent first)
    final sortedRecords = [...filteredRecords];
    sortedRecords.sort((a, b) => b.date.compareTo(a.date));

    final totalDays = filteredRecords.length;
    final presentDays = filteredRecords
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final leaveDays = filteredRecords
        .where((r) => r.status == AttendanceStatus.leave)
        .length;
    final absentDays = filteredRecords
        .where((r) => r.status == AttendanceStatus.absent)
        .length;
    final attendancePercentage = totalDays == 0 ? 0.0 : presentDays / totalDays;

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text(
                'My Attendance',
                style: TextStyle(color: AppColors.white),
              ),
              backgroundColor: AppColors.primaryStudent,
              foregroundColor: Colors.white,
              iconTheme: IconThemeData(color: AppColors.white),
            ),
      body: isLoading && attendanceRecords.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<StudentAttendanceNotifier>().fetchAttendance(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.red.shade100,
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
                            center: Text(
                              "${(attendancePercentage * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            progressColor: AppColors.primaryStudent,
                            backgroundColor: Colors.green.withOpacity(0.2),
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatItem(
                                'Total Classes',
                                totalDays.toString(),
                              ),
                              _buildStatItem(
                                'Present',
                                presentDays.toString(),
                                color: AppColors.primaryStudent,
                              ),
                              _buildStatItem(
                                'Leave',
                                leaveDays.toString(),
                                color: Colors.orange,
                              ),
                              _buildStatItem(
                                'Absent',
                                absentDays.toString(),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter Attendance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedDate == null
                                              ? 'All Dates'
                                              : DateFormat(
                                                  'MMM d, yyyy',
                                                ).format(_selectedDate!),
                                          style: TextStyle(
                                            color: _selectedDate == null
                                                ? Colors.grey.shade600
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (_selectedDate != null)
                                          GestureDetector(
                                            onTap: () => setState(
                                              () => _selectedDate = null,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.grey,
                                            ),
                                          )
                                        else
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _selectedSubjectId,
                                      hint: const Text('All Subjects'),
                                      items: [
                                        const DropdownMenuItem(
                                          value: 'all',
                                          child: Text('All Subjects'),
                                        ),
                                        ...subjects.entries.map((e) {
                                          return DropdownMenuItem(
                                            value: e.key,
                                            child: Text(e.value),
                                          );
                                        }),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == 'all') {
                                            _selectedSubjectId = null;
                                          } else {
                                            _selectedSubjectId = value;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    if (sortedRecords.isEmpty && !isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No attendance records found for the selected filters.',
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedRecords.length,
                        itemBuilder: (context, index) {
                          final record = sortedRecords[index];
                          final isPresent =
                              record.status == AttendanceStatus.present;
                          final isLeave =
                              record.status == AttendanceStatus.leave;

                          final subjectName =
                              record.subjectInfo?.name ?? 'Unknown Subject';
                          final timeStr = record.routineInfo != null
                              ? '${record.routineInfo!.startTime} - ${record.routineInfo!.endTime}'
                              : null;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPresent
                                  ? Colors.green.withOpacity(0.1)
                                  : (isLeave
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1)),
                              child: Icon(
                                isPresent
                                    ? Icons.check_circle
                                    : (isLeave ? Icons.info : Icons.cancel),
                                color: isPresent
                                    ? AppColors.primaryStudent
                                    : (isLeave ? Colors.orange : Colors.red),
                              ),
                            ),
                            title: Text(
                              subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'EEEE, MMM d, yyyy',
                                  ).format(record.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (timeStr != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? Colors.green.withOpacity(0.1)
                                    : (isLeave
                                          ? Colors.orange.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                record.status.name
                                        .substring(0, 1)
                                        .toUpperCase() +
                                    record.status.name.substring(1),
                                style: TextStyle(
                                  color: isPresent
                                      ? AppColors.primaryStudent
                                      : (isLeave ? Colors.orange : Colors.red),

                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    if (isLoading && attendanceRecords.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
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
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
