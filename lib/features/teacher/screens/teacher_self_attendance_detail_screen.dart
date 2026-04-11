import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/teacher/providers/teacher_dashboard_provider.dart';
import 'package:smart_school/models/school_models.dart';

class TeacherSelfAttendanceDetailScreen extends StatefulWidget {
  final String date; // Format: DD/MM/YYYY

  const TeacherSelfAttendanceDetailScreen({super.key, required this.date});

  @override
  State<TeacherSelfAttendanceDetailScreen> createState() => _TeacherSelfAttendanceDetailScreenState();
}

class _TeacherSelfAttendanceDetailScreenState extends State<TeacherSelfAttendanceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherDashboardProvider>().fetchTodayAttendance(widget.date);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherDashboardProvider>();
    final attendance = provider.todayAttendance;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Attendance Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _buildErrorWidget(provider.error!)
              : attendance == null
                  ? _buildEmptyWidget()
                  : _buildAttendanceDetails(attendance),
    );
  }

  Widget _buildAttendanceDetails(TeacherSelfAttendance attendance) {
    final isPresent = attendance.status.toLowerCase() == 'present';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(isPresent, attendance.status),
          const SizedBox(height: 24),
          _buildInfoSection(attendance),
          const SizedBox(height: 24),
          _buildLocationCard(attendance),
          const SizedBox(height: 32),
          _buildTimelineCard(attendance),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(bool isPresent, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: isPresent ? Colors.green : Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPresent ? 'You are marked as present' : 'You are marked as absent',
            style: TextStyle(
              color: isPresent ? Colors.green.shade600 : Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(TeacherSelfAttendance attendance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today, 'Date', attendance.date),
          const Divider(height: 32),
          _buildInfoRow(Icons.access_time, 'Check-in Time', attendance.time),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.straighten,
            'Distance from School',
            '${attendance.distanceFromCenter.toStringAsFixed(2)} meters',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationCard(TeacherSelfAttendance attendance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Location Captured',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCoordItem('Latitude', attendance.lat),
              const SizedBox(width: 24),
              _buildCoordItem('Longitude', attendance.lon),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blue.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineCard(TeacherSelfAttendance attendance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Metadata',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildTimelineItem(
                'Registered At',
                DateFormat('MMM d, yyyy - hh:mm a').format(attendance.createdAt),
                isLast: false,
              ),
              _buildTimelineItem(
                'Last Updated',
                DateFormat('MMM d, yyyy - hh:mm a').format(attendance.updatedAt),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, {required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.green.shade100,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ],
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
            'No attendance record found for this date',
            style: TextStyle(color: Colors.grey, fontSize: 16),
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
              onPressed: () => context.read<TeacherDashboardProvider>().fetchTodayAttendance(widget.date),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
