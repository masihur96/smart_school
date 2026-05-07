import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_management_provider.dart';

class TeacherAttendanceManagementScreen extends StatefulWidget {
  const TeacherAttendanceManagementScreen({super.key});

  @override
  State<TeacherAttendanceManagementScreen> createState() => _TeacherAttendanceManagementScreenState();
}

class _TeacherAttendanceManagementScreenState extends State<TeacherAttendanceManagementScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceManagementProvider>().fetchTeacherAttendance(
        name: _searchController.text,
        date: _selectedDate,
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceManagementProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Attendance"),
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search by Teacher Name...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (value) => _fetchData(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B4B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_today, color: Color(0xFF1E1B4B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    if (_searchController.text.isNotEmpty)
                      Text(
                        "Results for '${_searchController.text}'",
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(child: Text("Error: ${provider.error}"))
                    : provider.teacherAttendance.isEmpty
                        ? const Center(child: Text("No records found"))
                        : ListView.builder(
                            itemCount: provider.teacherAttendance.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final record = provider.teacherAttendance[index];
                              final status = record['status']?.toString().toLowerCase();
                              final inTime = record['startTime'] ?? "--:--";
                              final outTime = record['endTime'] ?? "--:--";

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue.withOpacity(0.1),
                                          child: Text(
                                            (record['teacherName'] ?? record['name'] ?? "?")[0].toUpperCase(),
                                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        title: Text(
                                          record['teacherName'] ?? record['name'] ?? "Unknown Teacher",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(record['designation'] ?? "Teacher"),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            record['status']?.toString().toUpperCase() ?? "UNKNOWN",
                                            style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildDetailItem(Icons.login, "In Time", inTime, Colors.green),
                                          _buildDetailItem(Icons.logout, "Out Time", outTime, Colors.blue),
                                          _buildDetailItem(Icons.location_on, "Location", 
                                            record['lat'] != null ? "View" : "N/A", Colors.orange),
                                        ],
                                      ),
                                    ],
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

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'clock-in':
      case 'present':
        return Colors.green;
      case 'clock-out':
        return Colors.blue;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
