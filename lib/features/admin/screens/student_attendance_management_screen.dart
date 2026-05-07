import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_management_provider.dart';

class StudentAttendanceManagementScreen extends StatefulWidget {
  const StudentAttendanceManagementScreen({super.key});

  @override
  State<StudentAttendanceManagementScreen> createState() => _StudentAttendanceManagementScreenState();
}

class _StudentAttendanceManagementScreenState extends State<StudentAttendanceManagementScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceManagementProvider>().fetchStudentAttendance(
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
        title: const Text("Student Attendance"),
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
                          hintText: "Search by Student Name...",
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
                    : provider.studentAttendance.isEmpty
                        ? const Center(child: Text("No records found"))
                        : ListView.builder(
                            itemCount: provider.studentAttendance.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final record = provider.studentAttendance[index];
                              // Assuming record structure from the API
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.purple.withOpacity(0.1),
                                    child: Text(
                                      (record['studentName'] ?? record['name'] ?? "?")[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    record['studentName'] ?? record['name'] ?? "Unknown Student",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text("Class: ${record['className'] ?? 'N/A'} - Section: ${record['sectionName'] ?? 'N/A'}"),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(record['status']?.toString().toLowerCase()).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      record['status']?.toString().toUpperCase() ?? "UNKNOWN",
                                      style: TextStyle(
                                        color: _getStatusColor(record['status']?.toString().toLowerCase()),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
