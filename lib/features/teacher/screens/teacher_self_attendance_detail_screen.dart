import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/teacher_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/teacher/providers/teacher_attendance_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.teacherAttendanceLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.border.withOpacity(0.1),
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(isAdmin, teachers),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryTeacher,
                    ),
                  )
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isAdmin) ...[
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Teacher',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(
                  Icons.person_search,
                  color: AppColors.textSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryTeacher,
                    width: 1.5,
                  ),
                ),
              ),
              value: _selectedTeacherId,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(AppLocalizations.of(context)!.teachers),
                ),
                ...teachers.map(
                  (t) => DropdownMenuItem(
                    value: t.userId,
                    child: Text(t.user?.name ?? 'Unknown'),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedTeacherId = val);
                _fetchData();
              },
            ),
            const SizedBox(height: 16),
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
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primaryTeacher,
                              onPrimary: AppColors.white,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _fetchData();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: _selectedDate == null
                              ? AppColors.textSecondary
                              : AppColors.primaryTeacher,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Filter by Date'
                              : DateFormat('dd MMM yyyy')
                                  .format(_selectedDate!),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _selectedDate == null
                                ? FontWeight.normal
                                : FontWeight.w500,
                            color: _selectedDate == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedDate != null ||
                  (isAdmin && _selectedTeacherId != null)) ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = null;
                      if (isAdmin) _selectedTeacherId = null;
                    });
                    _fetchData();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.filter_alt_off,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<TeacherSelfAttendance> list) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final attendance = list[index];
        return _buildAttendanceCard(attendance);
      },
    );
  }

  Widget _buildAttendanceCard(TeacherSelfAttendance attendance) {
    final isPresent = attendance.status.toLowerCase() == 'clock-in' || attendance.status.toLowerCase() == 'present';
    final teacherName = attendance.teacher?.name ?? 'Teacher';
    final accentColor = isPresent ? Colors.green : Colors.orange;

    String clockIn = _getClockInTime(attendance);
    String clockOut = _getClockOutTime(attendance);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored left strip
              Container(
                width: 5,
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPresent
                                  ? Icons.login_outlined
                                  : Icons.logout_outlined,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teacherName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDateOnly(attendance.time),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: accentColor.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              attendance.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: accentColor.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Clock In & Clock Out Info Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTimeBlock('Clock In', clockIn, Colors.green),
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: AppColors.border.withOpacity(0.1),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: _buildTimeBlock('Clock Out', clockOut, Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: AppColors.lightGrey),
                      ),
                      // Location Details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMiniInfo(
                            Icons.moving_rounded,
                            'Distance: ${attendance.distanceFromCenter.toStringAsFixed(1)}m',
                          ),
                          const SizedBox(width: 16),
                          _LocationAddressWidget(
                            lat: attendance.lat,
                            lon: attendance.lon,
                            flex: 2,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getClockInTime(TeacherSelfAttendance att) {
    if (att.startTime != null && att.startTime!.isNotEmpty) {
      return _formatTimeOnly(att.startTime);
    }
    if (att.status.toLowerCase() == 'clock-in') {
      return _formatTimeOnly(att.time);
    }
    return '--:--';
  }

  String _getClockOutTime(TeacherSelfAttendance att) {
    if (att.endTime != null && att.endTime!.isNotEmpty) {
      return _formatTimeOnly(att.endTime);
    }
    if (att.status.toLowerCase() == 'clock-out') {
      return _formatTimeOnly(att.time);
    }
    return '--:--';
  }

  String _formatTimeOnly(String? utcDate) {
    if (utcDate == null || utcDate.isEmpty) {
      return '--:--';
    }
    try {
      final localDate = DateTime.parse(utcDate).toLocal();
      return DateFormat('hh:mm a').format(localDate);
    } catch (e) {
      return '--:--';
    }
  }

  String _formatDateOnly(String? utcDate) {
    if (utcDate == null || utcDate.isEmpty) {
      return '--';
    }
    try {
      final localDate = DateTime.parse(utcDate).toLocal();
      return DateFormat('dd MMM yyyy').format(localDate);
    } catch (e) {
      return '--';
    }
  }

  Widget _buildTimeBlock(String label, String time, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String formatDate(String? utcDate) {
    if (utcDate == null || utcDate.isEmpty) {
      return '--';
    }
    final localDate = DateTime.parse(utcDate).toLocal();
    return DateFormat('dd MMM yyyy, hh:mm a').format(localDate);
  }

  Widget _buildMiniInfo(IconData icon, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.2,
              ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No attendance records found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters or date selection.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeacher,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeacher,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationAddressWidget extends StatefulWidget {
  final String lat;
  final String lon;
  final int flex;

  const _LocationAddressWidget({
    required this.lat,
    required this.lon,
    this.flex = 1,
  });

  @override
  State<_LocationAddressWidget> createState() => _LocationAddressWidgetState();
}

class _LocationAddressWidgetState extends State<_LocationAddressWidget> {
  String _address = 'Fetching location...';

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
            _address = 'Invalid coordinates';
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
    return Expanded(
      flex: widget.flex,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _address,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
