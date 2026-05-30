import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';

import '../providers/attendance_management_provider.dart';

class TeacherAttendanceManagementScreen extends StatefulWidget {
  const TeacherAttendanceManagementScreen({super.key});

  @override
  State<TeacherAttendanceManagementScreen> createState() =>
      _TeacherAttendanceManagementScreenState();
}

class _TeacherAttendanceManagementScreenState
    extends State<TeacherAttendanceManagementScreen> {
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
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
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
                      "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
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
                                subtitle: Text(
                                  record['teacher']?['designation'] ??
                                      record['designation'] ??
                                      "Teacher",
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
                                      formatDate(outTime),
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
    );
  }

  String formatDate(String? utcDate) {
    if (utcDate == null || utcDate.isEmpty) {
      return '--';
    }

    final localDate = DateTime.parse(utcDate).toLocal();

    return DateFormat('hh:mm a').format(localDate);
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
