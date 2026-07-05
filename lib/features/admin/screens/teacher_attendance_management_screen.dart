import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/utils/teacher_attendance_pdf_helper.dart';

import '../../../models/teacher_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/attendance_management_provider.dart';
import '../providers/teacher_provider.dart';

class TeacherAttendanceManagementScreen extends StatefulWidget {
  const TeacherAttendanceManagementScreen({super.key});

  @override
  State<TeacherAttendanceManagementScreen> createState() =>
      _TeacherAttendanceManagementScreenState();
}

class _TeacherAttendanceManagementScreenState
    extends State<TeacherAttendanceManagementScreen> {
  DateTimeRange? _selectedDateRange;
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
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
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
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _exportToPdf(context),
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export PDF",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),

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
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
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
                        child: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDateRange != null
                          ? "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} to ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}"
                          : "Date: All Time",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      Text(
                        "Results for '${_searchController.text}'",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
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

                      String dateStr = record['date']?.toString() ?? "N/A";
                      if (dateStr != "N/A") {
                        try {
                          dateStr = DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
                        } catch (_) {}
                      } else if (record['startTime'] != null) {
                        try {
                          dateStr = DateFormat('MMM dd, yyyy').format(DateTime.parse(record['startTime']).toLocal());
                        } catch (_) {}
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  child: Text(
                                    (record['teacher']?['name'] ??
                                            record['teacherName'] ??
                                            record['name'] ??
                                            "?")[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  record['teacher']?['name'] ??
                                      record['teacherName'] ??
                                      record['name'] ??
                                      "Unknown Teacher",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record['teacher']?['designation'] ??
                                          record['designation'] ??
                                          "Teacher",
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    record['status']
                                            ?.toString()
                                            .toUpperCase() ??
                                        "UNKNOWN",
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
                                children: [
                                  Expanded(
                                    child: _buildDetailItem(
                                      Icons.login,
                                      "In Time",
                                      formatDate(inTime),
                                      Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDetailItem(
                                      Icons.logout,
                                      "Out Time",
                                      outTime == null || outTime == "--:--"
                                          ? "N/A"
                                          : formatDate(outTime),
                                      Colors.blue,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildLocationDetailItem(
                                      Icons.location_on,
                                      "Location",
                                      record['lat']?.toString(),
                                      record['lon']?.toString(),
                                      Colors.orange,
                                    ),
                                  ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAttendanceBottomSheet(context),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Create Attendance"),
      ),
    );
  }

  void _showCreateAttendanceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateAttendanceBottomSheet(),
    );
  }

  String formatDate(String? utcDate) {
    if (utcDate == null || utcDate.isEmpty) {
      return '--';
    }

    final localDate = DateTime.parse(utcDate).toLocal();

    return DateFormat('hh:mm a').format(localDate);
  }

  Future<void> _exportToPdf(BuildContext context) async {
    final provider = context.read<AttendanceManagementProvider>();
    final authProvider = context.read<AuthNotifier>();

    if (provider.teacherAttendance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No attendance records to export")),
      );
      return;
    }

    try {
      await TeacherAttendancePdfHelper.generateAttendancePdf(
        attendanceList: provider.teacherAttendance,
        schoolName: authProvider.user?.school?.name ?? "Smart School",
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      );
    } catch (e, stack) {
      log("Error generating PDF: $e\n$stack");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to generate PDF: $e")));
    }
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLocationDetailItem(
    IconData icon,
    String label,
    String? lat,
    String? lon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        if (lat != null && lon != null)
          _LocationAddressText(
            lat: lat,
            lon: lon,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          )
        else
          const Text(
            "N/A",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
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

class _LocationAddressText extends StatefulWidget {
  final String lat;
  final String lon;
  final TextStyle style;

  const _LocationAddressText({
    required this.lat,
    required this.lon,
    required this.style,
  });

  @override
  State<_LocationAddressText> createState() => _LocationAddressTextState();
}

class _LocationAddressTextState extends State<_LocationAddressText> {
  String _address = 'Fetching...';

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    try {
      final lat = double.tryParse(widget.lat);
      final lon = double.tryParse(widget.lon);
      if (lat != null && lon != null) {
        final placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final addressParts = <String>[];
          if (place.name != null && place.name!.isNotEmpty) {
            addressParts.add(place.name!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality != null &&
              place.locality!.isNotEmpty &&
              !addressParts.contains(place.locality!)) {
            addressParts.add(place.locality!);
          }

          if (mounted) {
            setState(() {
              _address = addressParts.isNotEmpty
                  ? addressParts.join(', ')
                  : '${widget.lat}, ${widget.lon}';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _address = '${widget.lat}, ${widget.lon}';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _address = 'Invalid coords';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = '${widget.lat}, ${widget.lon}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _address,
      style: widget.style,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CreateAttendanceBottomSheet extends StatefulWidget {
  const _CreateAttendanceBottomSheet();

  @override
  State<_CreateAttendanceBottomSheet> createState() =>
      _CreateAttendanceBottomSheetState();
}

class _CreateAttendanceBottomSheetState
    extends State<_CreateAttendanceBottomSheet> {
  Teacher? _selectedTeacher;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 14, minute: 0);
  String _selectedStatus = 'clock-in';

  final List<String> _statuses = [
    'clock-in',
    'clock-out',
    'present',
    'absent',
    'leave',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeachersNotifier>().fetchTeachers();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() async {
    if (_selectedTeacher == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a teacher")));
      return;
    }

    // Format date as YYYY-MM-DD
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Format startTime and endTime as ISO strings
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final startIsoString = startDateTime.toUtc().toIso8601String();
    final endIsoString = endDateTime.toUtc().toIso8601String();

    await context.read<AttendanceManagementProvider>().createTeacherAttendance(
      teacherId: _selectedTeacher!.userId,
      date: formattedDate,
      status: _selectedStatus,
      startTime: startIsoString,
      endTime: endIsoString,
      time: startIsoString,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance created successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachersProvider = context.watch<TeachersNotifier>();
    final isCreating = context.watch<AttendanceManagementProvider>().isLoading;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Create Attendance",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (teachersProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<Teacher>(
                  decoration: InputDecoration(
                    labelText: "Select Teacher",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  value: _selectedTeacher,
                  items: teachersProvider.teachers.map((Teacher teacher) {
                    return DropdownMenuItem<Teacher>(
                      value: teacher,
                      child: Text(teacher.user?.name ?? "Unknown"),
                    );
                  }).toList(),
                  onChanged: (Teacher? newValue) {
                    setState(() {
                      _selectedTeacher = newValue;
                    });
                  },
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                value: _selectedStatus,
                items: _statuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Date",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Start Time",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_startTime.format(context)),
                            const Icon(Icons.access_time, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "End Time",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_endTime.format(context)),
                            const Icon(Icons.access_time, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isCreating ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAdmin,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Submit",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
