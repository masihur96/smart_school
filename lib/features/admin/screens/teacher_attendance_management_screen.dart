import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/utils/teacher_attendance_pdf_helper.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/teacher_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/attendance_management_provider.dart';
import '../providers/teacher_provider.dart';
import '../providers/routine_provider.dart';

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
  String _selectedStatus = 'ALL';
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AttendanceManagementProvider>().teacherAttendance.isEmpty) {
        _fetchData();
      }
      
      final authProvider = context.read<AuthNotifier>();
      final schoolId = authProvider.user?.schoolId;
      if (schoolId != null && context.read<RoutineNotifier>().state.isEmpty) {
        context.read<RoutineNotifier>().fetchAllRoutines(schoolId);
      }
      if (context.read<TeachersNotifier>().teachers.isEmpty) {
        context.read<TeachersNotifier>().fetchTeachers();
      }
    });
  }

  void _fetchData() {
    context.read<AttendanceManagementProvider>().fetchTeacherAttendance(
      name: _searchController.text,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );
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

  String _getStatusLabel(BuildContext context, String? status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status?.toLowerCase()) {
      case 'clock-in':
        return l10n.statusClockIn;
      case 'clock-out':
        return l10n.statusClockOut;
      case 'present':
        return l10n.statusPresent;
      case 'absent':
        return l10n.statusAbsent;
      case 'leave':
        return l10n.statusLeave;
      default:
        return status?.toUpperCase() ?? l10n.statusUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AttendanceManagementProvider>();
    final routineProvider = context.watch<RoutineNotifier>();
    final teachersProvider = context.watch<TeachersNotifier>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Get the target date
    final targetDate = _selectedDateRange?.start ?? DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(targetDate);

    // 2. Find teachers who have a routine on this day
    final allRoutines = routineProvider.state.values.expand((e) => e).toList();
    final teachersWithRoutineIds = allRoutines
        .where((r) => r.day.toLowerCase() == dayOfWeek.toLowerCase())
        .map((r) => r.teacherId)
        .toSet();

    // 3. Clone existing explicit records
    final List<Map<String, dynamic>> combinedRecords = provider.teacherAttendance
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // 4. Find which teachers already have a record
    final explicitlyRecordedTeacherIds = combinedRecords.map((r) {
      return (r['teacher']?['id'] ?? r['teacher']?['_id'] ?? r['teacherId'] ?? r['userId'])?.toString();
    }).toSet();

    // 5. Inject ABSENT records for teachers expected today but missing
    for (final teacherId in teachersWithRoutineIds) {
      if (teacherId.isNotEmpty && !explicitlyRecordedTeacherIds.contains(teacherId)) {
        final teacherInfo = teachersProvider.teachers.firstWhere(
            (t) => t.userId == teacherId, 
            orElse: () => Teacher(userId: teacherId, user: null));
            
        combinedRecords.add({
          'teacher': {
            'id': teacherId,
            'name': teacherInfo.user?.name ?? l10n.unknownTeacher,
            'designation': teacherInfo.designation,
            'phone': teacherInfo.user?.phone ?? teacherInfo.user?.phone,
          },
          'teacherId': teacherId,
          'status': 'absent',
          'date': targetDate.toIso8601String(),
          'startTime': null,
          'endTime': null,
        });
      }
    }

    final filteredAttendance = _selectedStatus == 'ALL'
        ? combinedRecords
        : combinedRecords
            .where((r) => r['status']?.toString().toUpperCase() == _selectedStatus)
            .toList();

    final totalCount = combinedRecords.length;
    final presentCount = combinedRecords.where((r) => r['status']?.toString().toUpperCase() == 'PRESENT').length;
    final absentCount = combinedRecords.where((r) => r['status']?.toString().toUpperCase() == 'ABSENT').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teacherAttendanceTitle),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            icon: Icon(_isFilterExpanded ? Icons.filter_list_off : Icons.filter_list),
            tooltip: 'Toggle Filters',
          ),
          IconButton(
            onPressed: () => _exportToPdf(context),
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: l10n.exportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: l10n.searchByTeacherNameHint,
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
                            color: const Color(0xFF1E1B4B).withValues(alpha: 0.1),
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
                            ? l10n.dateRangeFormat(
                                DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start),
                                DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end),
                              )
                            : l10n.dateAllTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        Text(
                          l10n.resultsForFormat(_searchController.text),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatusFilters(
                    context: context,
                    allCount: totalCount,
                    presentCount: presentCount,
                    absentCount: absentCount,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            crossFadeState: _isFilterExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          Expanded(
            child: provider.isLoading
                ? _TeacherAttendanceShimmer(isDark: isDark)
                : provider.error != null
                ? Center(child: Text(l10n.errorLabel(provider.error!)))
                : provider.teacherAttendance.isEmpty
                ? Center(child: Text(l10n.noRecordsFound))
                : filteredAttendance.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt_off_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noStatusRecordsFound(
                            _getStatusLabel(context, _selectedStatus),
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedStatus = 'ALL';
                            });
                          },
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: Text(l10n.showAll),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _fetchData(),
                    child: ListView.builder(
                      itemCount: filteredAttendance.length,
                      padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final record = filteredAttendance[index];
                      final status = record['status']?.toString().toLowerCase();
                      final inTime = record['startTime'] ?? "--:--";
                      final outTime = record['endTime'] ?? "--:--";

                      final teacherPhone = record['teacher']?['phone']?.toString() ?? 
                                           record['teacher']?['guardianContact']?.toString() ?? 
                                           record['teacher']?['user']?['phone']?.toString() ??
                                           record['phone']?.toString();

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
                                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
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
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        record['teacher']?['name'] ??
                                            record['teacherName'] ??
                                            record['name'] ??
                                            l10n.unknownTeacher,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (teacherPhone != null && teacherPhone.isNotEmpty)
                                      InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () async {
                                          final Uri launchUri = Uri(
                                            scheme: 'tel',
                                            path: teacherPhone,
                                          );
                                          if (await canLaunchUrl(launchUri)) {
                                            await launchUrl(launchUri);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(Icons.phone, color: AppColors.primaryAdmin, size: 16),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record['teacher']?['designation'] ??
                                          record['designation'] ??
                                          l10n.teacherLabel,
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
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getStatusLabel(context, status),
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
                                      l10n.inTime,
                                      formatDate(inTime),
                                      Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDetailItem(
                                      Icons.logout,
                                      l10n.outTime,
                                      outTime == null || outTime == "--:--"
                                          ? "N/A"
                                          : formatDate(outTime),
                                      Colors.blue,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildLocationDetailItem(
                                      context,
                                      Icons.location_on,
                                      l10n.locationLabel,
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAttendanceBottomSheet(context),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.createAttendance),
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
    if (utcDate == null || utcDate.isEmpty || utcDate == '--:--' || utcDate == '--') {
      return '--';
    }

    try {
      final localDate = DateTime.parse(utcDate).toLocal();
      return DateFormat('hh:mm a').format(localDate);
    } catch (e) {
      return utcDate; // Fallback to raw string if parsing fails
    }
  }

  Future<void> _exportToPdf(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<AttendanceManagementProvider>();
    final authProvider = context.read<AuthNotifier>();

    if (provider.teacherAttendance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noAttendanceRecordsToExport)),
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.failedToGeneratePdf(e.toString()))));
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
    BuildContext context,
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
  Widget _buildStatusFilters({
    required BuildContext context,
    required int allCount,
    required int presentCount,
    required int absentCount,
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final statusItems = [
      {
        'key': 'ALL',
        'label': l10n.statusAll,
        'count': allCount,
        'color': AppColors.primaryAdmin,
        'icon': Icons.grid_view_rounded,
      },
      {
        'key': 'PRESENT',
        'label': l10n.statusPresent,
        'count': presentCount,
        'color': const Color(0xFF10B981),
        'icon': Icons.check_circle_rounded,
      },
      {
        'key': 'ABSENT',
        'label': l10n.statusAbsent,
        'count': absentCount,
        'color': const Color(0xFFEF4444),
        'icon': Icons.cancel_rounded,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statusItems.map((item) {
          final key = item['key'] as String;
          final label = item['label'] as String;
          final count = item['count'] as int;
          final color = item['color'] as Color;
          final icon = item['icon'] as IconData;
          final isSelected = _selectedStatus == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedStatus = key;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : (isDark
                            ? color.withValues(alpha: 0.15)
                            : color.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.35),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
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
  String? _address;

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
            _address = null; // Will show localized fallback in build
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
    final l10n = AppLocalizations.of(context)!;
    final displayText = _address ?? (double.tryParse(widget.lat) == null ? l10n.invalidCoords : l10n.fetchingLabel);
    return Text(
      displayText,
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
  TimeOfDay? _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _endTime;
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

  String _getStatusLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'clock-in':
        return l10n.statusClockIn;
      case 'clock-out':
        return l10n.statusClockOut;
      case 'present':
        return l10n.statusPresent;
      case 'absent':
        return l10n.statusAbsent;
      case 'leave':
        return l10n.statusLeave;
      default:
        return status.toUpperCase();
    }
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
    final initialTime = isStart
        ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 14, minute: 0));
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
    final l10n = AppLocalizations.of(context)!;
    if (_selectedTeacher == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectTeacher)));
      return;
    }

    // Format date as YYYY-MM-DD
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Format startTime and endTime as ISO strings if present
    final String? startIsoString = _startTime != null
        ? DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _startTime!.hour,
            _startTime!.minute,
          ).toUtc().toIso8601String()
        : null;

    final String? endIsoString = _endTime != null
        ? DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _endTime!.hour,
            _endTime!.minute,
          ).toUtc().toIso8601String()
        : null;

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
        SnackBar(content: Text(l10n.attendanceCreatedSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  Text(
                    l10n.createAttendance,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    labelText: l10n.selectTeacher,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  initialValue: _selectedTeacher,
                  items: teachersProvider.teachers.map((Teacher teacher) {
                    return DropdownMenuItem<Teacher>(
                      value: teacher,
                      child: Text(teacher.user?.name ?? l10n.unknownTeacher),
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
                  labelText: l10n.statusLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                initialValue: _selectedStatus,
                items: _statuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(_getStatusLabel(context, status)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                      if (_selectedStatus == 'absent' || _selectedStatus == 'leave') {
                        _startTime = null;
                        _endTime = null;
                      } else if (_selectedStatus == 'clock-in') {
                        _startTime ??= const TimeOfDay(hour: 8, minute: 0);
                        _endTime = null;
                      } else if (_selectedStatus == 'clock-out') {
                        _startTime ??= const TimeOfDay(hour: 8, minute: 0);
                        _endTime ??= const TimeOfDay(hour: 14, minute: 0);
                      } else if (_selectedStatus == 'present') {
                        _startTime ??= const TimeOfDay(hour: 8, minute: 0);
                        _endTime ??= const TimeOfDay(hour: 14, minute: 0);
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.dateLabel,
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
              if (_selectedStatus == 'absent' || _selectedStatus == 'leave')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.timeNotRequiredInfo(_getStatusLabel(context, _selectedStatus)),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.startTimeLabel,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            suffixIcon: _startTime != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () =>
                                        setState(() => _startTime = null),
                                  )
                                : const Icon(Icons.access_time, size: 20),
                          ),
                          child: Text(
                            _startTime != null
                                ? _startTime!.format(context)
                                : l10n.notSet,
                            style: TextStyle(
                              color: _startTime != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
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
                            labelText: l10n.endTimeLabel,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            suffixIcon: _endTime != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () =>
                                        setState(() => _endTime = null),
                                  )
                                : const Icon(Icons.access_time, size: 20),
                          ),
                          child: Text(
                            _endTime != null
                                ? _endTime!.format(context)
                                : l10n.notSet,
                            style: TextStyle(
                              color: _endTime != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
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
                    : Text(
                        l10n.submitButton,
                        style: const TextStyle(
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

// ─── Shimmer skeleton ────────────────────────────────────────────────────────

class _TeacherAttendanceShimmer extends StatelessWidget {
  final bool isDark;
  const _TeacherAttendanceShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, _) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white,
                    ),
                    title: Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      width: 60,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white),
                  Row(
                    children: [
                      // In Time
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 10,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 12,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Out Time
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 10,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 12,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Location
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 10,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 12,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
