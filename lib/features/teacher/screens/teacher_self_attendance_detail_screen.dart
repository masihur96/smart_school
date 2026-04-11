import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/teacher_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/teacher/providers/teacher_attendance_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/user_model.dart';

class TeacherSelfAttendanceDetailScreen extends StatefulWidget {
  final String? teacherId;
  final String schoolId;
  final String? initialDate; // Format: DD/MM/YYYY

  const TeacherSelfAttendanceDetailScreen({
    super.key,
    this.teacherId,
    required this.schoolId,
    this.initialDate,
  });

  @override
  State<TeacherSelfAttendanceDetailScreen> createState() =>
      _TeacherSelfAttendanceDetailScreenState();
}

class _TeacherSelfAttendanceDetailScreenState
    extends State<TeacherSelfAttendanceDetailScreen> {
  String? _selectedTeacherId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedTeacherId = widget.teacherId;
    if (widget.initialDate != null) {
      try {
        _selectedDate = DateFormat('dd/MM/yyyy').parse(widget.initialDate!);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      final auth = context.read<AuthNotifier>();
      if (auth.user?.role == UserRole.admin) {
        context.read<TeachersNotifier>().fetchTeachers();
      }
    });
  }

  void _fetchData() {
    final dateStr = _selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
        : null;
    context.read<TeacherAttendanceProvider>().fetchTeacherAttendance(
      schoolId: widget.schoolId,
      teacherId: _selectedTeacherId,
      date: dateStr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final isAdmin = auth.user?.role == UserRole.admin;
    final provider = context.watch<TeacherAttendanceProvider>();
    final teachers = context.watch<TeachersNotifier>().teachers;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Teacher Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterSection(isAdmin, teachers),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? _buildErrorWidget(provider.error!)
                    : provider.attendanceList.isEmpty
                        ? _buildEmptyWidget()
                        : _buildAttendanceList(provider.attendanceList),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isAdmin, List<dynamic> teachers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isAdmin) ...[
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Teacher',
                prefixIcon: const Icon(Icons.person_search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: _selectedTeacherId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Teachers')),
                ...teachers.map((t) => DropdownMenuItem(
                      value: t.userId,
                      child: Text(t.user?.name ?? 'Unknown'),
                    )),
              ],
              onChanged: (val) {
                setState(() => _selectedTeacherId = val);
                _fetchData();
              },
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _fetchData();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate == null
                              ? 'Filter by Date'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null ? Colors.grey.shade600 : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedDate != null || (isAdmin && _selectedTeacherId != null))
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                      if (isAdmin) _selectedTeacherId = null;
                    });
                    _fetchData();
                  },
                  icon: const Icon(Icons.clear, color: Colors.red),
                  tooltip: 'Clear Filters',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<TeacherSelfAttendance> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final attendance = list[index];
        return _buildAttendanceCard(attendance);
      },
    );
  }

  Widget _buildAttendanceCard(TeacherSelfAttendance attendance) {
    final isPresent = attendance.status.toLowerCase() == 'present';
    final teacherName = attendance.teacher?.name ?? 'Teacher';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isPresent ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                isPresent ? Icons.check_circle : Icons.cancel,
                color: isPresent ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              teacherName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${attendance.date} at ${attendance.time}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Text(
                attendance.status.toUpperCase(),
                style: TextStyle(
                  color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniInfo(Icons.location_on, 'Dist: ${attendance.distanceFromCenter.toStringAsFixed(1)}m'),
                _buildMiniInfo(Icons.my_location, '${attendance.lat}, ${attendance.lon}', flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No attendance records found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchData,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading attendance: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
