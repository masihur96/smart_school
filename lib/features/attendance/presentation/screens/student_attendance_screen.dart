import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teacher_app/core/theme.dart';
import 'package:teacher_app/data/mock_data/mock_data.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final bool isTab;
  const StudentAttendanceScreen({super.key, this.isTab = false});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  late Map<String, String> _currentAttendance;
  
  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  void _loadAttendance() {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final existingData = MockData.studentAttendance[dateKey];
    
    _currentAttendance = {
      for (var student in MockData.students)
        student['id']: existingData?.firstWhere(
              (a) => a['studentId'] == student['id'],
              orElse: () => {'status': 'Present'},
            )['status'] ?? 'Present'
    };
  }

  bool get _isToday => DateFormat('yyyy-MM-dd').format(_selectedDate) == MockData.today;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                  _loadAttendance();
                });
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: AppColors.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM dd').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      _isToday ? 'You can mark/update today' : 'History Mode (Read-Only)',
                      style: TextStyle(
                        color: _isToday ? AppColors.success : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (_isToday)
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance submitted successfully')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    ),
                    child: const Text('Submit Attendance'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: MockData.students.length,
              itemBuilder: (context, index) {
                final student = MockData.students[index];
                final status = _currentAttendance[student['id']]!;
                
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade100),
                  ),
                  child: ListTile(
                    title: Text(student['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Roll: ${student['roll']}'),
                    trailing: _isToday 
                      ? SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Present', label: Text('P')),
                            ButtonSegment(value: 'Absent', label: Text('A')),
                          ],
                          selected: {status},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _currentAttendance[student['id']] = newSelection.first;
                            });
                          },
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: status == 'Present' ? AppColors.success : AppColors.error,
                            selectedForegroundColor: Colors.white,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: status == 'Present' 
                                ? AppColors.success.withOpacity(0.1) 
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: status == 'Present' ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
