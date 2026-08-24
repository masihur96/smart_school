import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/utils/class_routine_pdf_helper.dart';
import 'package:smart_school/core/utils/student_attendance_pdf_helper.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/models/period_attendance_model.dart';
import 'package:smart_school/models/school_models.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/attendance_management_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StudentAttendanceManagementScreen extends StatefulWidget {
  const StudentAttendanceManagementScreen({super.key});

  @override
  State<StudentAttendanceManagementScreen> createState() =>
      _StudentAttendanceManagementScreenState();
}

class _StudentAttendanceManagementScreenState
    extends State<StudentAttendanceManagementScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<SubjectSetupNotifier>().subjects.isEmpty) {
        context.read<SubjectSetupNotifier>().fetchSchoolData();
      }

      if (context
          .read<AttendanceManagementProvider>()
          .studentAttendance
          .isEmpty) {
        _fetchData();
      }
    });
  }

  void _fetchData({int page = 1}) {
    context.read<AttendanceManagementProvider>().fetchStudentAttendance(
      name: _searchController.text,
      startDate: _startDate,
      endDate: _endDate,
      classId: _selectedClassId,
      sectionId: _selectedSectionId,
      subjectId: _selectedSubjectId,
      page: page,
      limit: 100,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceManagementProvider>();
    final classProvider = context.watch<ClassSetupNotifier>();
    final sectionProvider = context.watch<SectionSetupNotifier>();
    final subjectProvider = context.watch<SubjectSetupNotifier>();

    final user = context.read<AuthNotifier>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredSections = _selectedClassId == null
        ? sectionProvider.sections
        : sectionProvider.sections
              .where((s) => s.classId == _selectedClassId)
              .toList();

    final filteredSubjects = _selectedClassId == null
        ? subjectProvider.subjects
        : subjectProvider.subjects
              .where((s) => s.classId == _selectedClassId)
              .toList();

    final allRecords = attendanceProvider.studentAttendance;
    final filteredAttendance = _selectedStatus == 'ALL'
        ? allRecords
        : allRecords
              .where((r) => r.status.trim().toUpperCase() == _selectedStatus)
              .toList();

    final totalCount = allRecords.length;
    final presentCount = allRecords
        .where((r) => r.status.trim().toUpperCase() == 'PRESENT')
        .length;
    final absentCount = allRecords
        .where((r) => r.status.trim().toUpperCase() == 'ABSENT')
        .length;
    final lateCount = allRecords
        .where((r) => r.status.trim().toUpperCase() == 'LATE')
        .length;
    final leaveCount = allRecords
        .where((r) => r.status.trim().toUpperCase() == 'LEAVE')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Student Attendance",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _exportToPdf(context, filteredAttendance),
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
                          hintText: "Search by Student Name...",
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
                          color: (_startDate != null && _endDate != null)
                              ? AppColors.primaryAdmin
                              : AppColors.primaryAdmin.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: (_startDate != null && _endDate != null)
                              ? Colors.white
                              : AppColors.primaryAdmin,
                        ),
                      ),
                    ),
                    if (_startDate != null && _endDate != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                          _fetchData();
                        },
                        icon: const Icon(Icons.clear, color: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterDropdown<ClassRoom>(
                        hint: "Class",
                        value: _selectedClassId,
                        items: classProvider.classes
                            .where((c) => c.schoolId == user?.schoolId)
                            .toList(),
                        itemLabel: (item) => item.name,
                        itemValue: (item) => item.id,
                        onChanged: (value) {
                          setState(() {
                            _selectedClassId = value;
                            _selectedSectionId = null;
                            _selectedSubjectId = null;
                          });
                          _fetchData();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown<Section>(
                        hint: "Section",
                        value: _selectedSectionId,
                        items: filteredSections,
                        itemLabel: (item) => item.name,
                        itemValue: (item) => item.id,
                        onChanged: (value) {
                          setState(() {
                            _selectedSectionId = value;
                          });
                          _fetchData();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown<Subject>(
                        hint: "Subject",
                        value: _selectedSubjectId,
                        items: filteredSubjects,
                        itemLabel: (item) => item.name,
                        itemValue: (item) => item.id,
                        onChanged: (value) {
                          setState(() {
                            _selectedSubjectId = value;
                          });
                          _fetchData();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                _buildStatusFilters(
                  allCount: totalCount,
                  presentCount: presentCount,
                  absentCount: absentCount,
                  lateCount: lateCount,
                  leaveCount: leaveCount,
                  isDark: isDark,
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (_startDate == null || _endDate == null)
                          ? "All Dates"
                          : "${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      _selectedStatus == 'ALL'
                          ? "Total: ${attendanceProvider.total}"
                          : "Showing: ${filteredAttendance.length} / ${allRecords.length}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: attendanceProvider.isLoading
                ? _AttendanceShimmer(isDark: isDark)
                : attendanceProvider.error != null
                ? Center(child: Text("Error: ${attendanceProvider.error}"))
                : attendanceProvider.studentAttendance.isEmpty
                ? const Center(child: Text("No records found"))
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
                          "No $_selectedStatus records found",
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
                          label: const Text("Show All"),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _fetchData(),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredAttendance.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final record = filteredAttendance[index];
                        return _buildAttendanceCard(context, record, isDark);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters({
    required int allCount,
    required int presentCount,
    required int absentCount,
    required int lateCount,
    required int leaveCount,
    required bool isDark,
  }) {
    final statusItems = [
      {
        'key': 'ALL',
        'label': 'ALL',
        'count': allCount,
        'color': AppColors.primaryAdmin,
        'icon': Icons.grid_view_rounded,
      },
      {
        'key': 'PRESENT',
        'label': 'PRESENT',
        'count': presentCount,
        'color': const Color(0xFF10B981),
        'icon': Icons.check_circle_rounded,
      },
      {
        'key': 'ABSENT',
        'label': 'ABSENT',
        'count': absentCount,
        'color': const Color(0xFFEF4444),
        'icon': Icons.cancel_rounded,
      },
      {
        'key': 'LATE',
        'label': 'LATE',
        'count': lateCount,
        'color': const Color(0xFF3B82F6),
        'icon': Icons.schedule_rounded,
      },
      {
        'key': 'LEAVE',
        'label': 'LEAVE',
        'count': leaveCount,
        'color': const Color(0xFFF59E0B),
        'icon': Icons.event_busy_rounded,
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

  Future<void> _exportToPdf(
    BuildContext context,
    List<PeriodAttendance> attendanceToExport,
  ) async {
    final authProvider = context.read<AuthNotifier>();
    final classProvider = context.read<ClassSetupNotifier>();
    final sectionProvider = context.read<SectionSetupNotifier>();
    final subjectProvider = context.read<SubjectSetupNotifier>();

    if (attendanceToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No attendance records to export")),
      );
      return;
    }

    final className = _selectedClassId != null
        ? classProvider.classes
              .cast<ClassRoom?>()
              .firstWhere((c) => c?.id == _selectedClassId, orElse: () => null)
              ?.name
        : null;
    final sectionName = _selectedSectionId != null
        ? sectionProvider.sections
              .cast<Section?>()
              .firstWhere(
                (s) => s?.id == _selectedSectionId,
                orElse: () => null,
              )
              ?.name
        : null;
    final subjectName = _selectedSubjectId != null
        ? subjectProvider.subjects
              .cast<Subject?>()
              .firstWhere(
                (s) => s?.id == _selectedSubjectId,
                orElse: () => null,
              )
              ?.name
        : null;

    try {
      await StudentAttendancePdfHelper.generateAttendancePdf(
        attendanceList: attendanceToExport,
        schoolName: authProvider.user?.school?.name ?? "Smart School",
        className: className,
        sectionName: sectionName,
        subjectName: subjectName,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e, stack) {
      log("Error generating PDF: $e\n$stack");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to generate PDF: $e")));
    }
  }

  String formatDate(String? utcDate) {
    if (utcDate == null || utcDate.isEmpty) {
      return '--';
    }

    final localDate = DateTime.parse(utcDate).toLocal();

    return DateFormat('dd MMM yyyy, hh:mm a').format(localDate);
  }

  Widget _buildAttendanceCard(
    BuildContext context,
    PeriodAttendance record,
    bool isDark,
  ) {
    final statusColor = _getStatusColor(record.status);
    final statusIcon = _getStatusIcon(record.status);

    // Extract student avatar & roll number
    final studentAvatar =
        record.student?['avatar'] as String? ??
        record.student?['avatarUrl'] as String? ??
        record.student?['photo'] as String? ??
        record.student?['image'] as String? ??
        (record.student?['user'] != null
            ? record.student!['user']['avatar'] as String?
            : null);

    final rollNumber =
        record.student?['rollNumber']?.toString() ??
        record.student?['rollId']?.toString() ??
        record.student?['roll_number']?.toString();

    final className = record.classInfo?.name ?? '';
    final sectionName = record.sectionInfo?.name ?? '';
    final subjectName = record.subjectInfo?.name ?? '';
    final teacherName =
        record.teacherInfo?.name ??
        record.teacherInfo?.name ??
        record.routineInfo?.teacherEntity?.name ??
        'N/A';
    final startTime = record.routineInfo?.startTime ?? '';
    final endTime = record.routineInfo?.endTime ?? '';
    final roomNumber = record.routineInfo?.roomNumber ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: statusColor.withValues(alpha: 0.12),
            backgroundImage: studentAvatar != null && studentAvatar.isNotEmpty
                ? CachedNetworkImageProvider(
                    studentAvatar,
                    cacheKey: studentAvatar.split('?').first,
                  )
                : null,
            child: studentAvatar != null && studentAvatar.isNotEmpty
                ? null
                : Text(
                    record.studentName.isNotEmpty
                        ? record.studentName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  record.studentName.isNotEmpty
                      ? record.studentName
                      : 'Unknown Student',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      record.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Academic Badges Row (Class, Section, Roll, Subject)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (className.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAdmin.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 11,
                              color: AppColors.primaryAdmin,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              sectionName.isNotEmpty
                                  ? '$className • Sec $sectionName'
                                  : className,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.primaryAdmin,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (rollNumber != null && rollNumber.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Roll #$rollNumber',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (subjectName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 11,
                              color: Colors.indigo.shade700,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              subjectName,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.indigo.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Date row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(record.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade900.withValues(alpha: 0.5)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _buildDetailItem(
                    icon: Icons.person_outline,
                    iconColor: Colors.teal,
                    label: 'Teacher',
                    value: teacherName,
                    isDark: isDark,
                  ),
                    if (startTime.isNotEmpty || endTime.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailItem(
                        icon: Icons.schedule_outlined,
                        iconColor: Colors.blue,
                        label: 'Time Slot',
                        value: ClassRoutinePdfHelper.formatSlotDisplay(
                          startTime,
                          endTime,
                        ),
                        isDark: isDark,
                      ),
                    ],
                  if (roomNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailItem(
                      icon: Icons.meeting_room_outlined,
                      iconColor: Colors.orange,
                      label: 'Room',
                      value: roomNumber,
                      isDark: isDark,
                    ),
                  ],
                  if (record.id.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailItem(
                      icon: Icons.tag_outlined,
                      iconColor: Colors.purple,
                      label: 'Record ID',
                      value: record.id.length > 12
                          ? '${record.id.substring(0, 12)}...'
                          : record.id,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown<T>({
    required String hint,
    required String? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required String Function(T) itemValue,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text("All $hint", style: const TextStyle(fontSize: 12)),
            ),
            ...items.map((item) {
              return DropdownMenuItem<String>(
                value: itemValue(item),
                child: Text(
                  itemLabel(item),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return const Color(0xFF10B981);
      case 'absent':
        return const Color(0xFFEF4444);
      case 'leave':
        return const Color(0xFFF59E0B);
      case 'late':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return Icons.check_circle_rounded;
      case 'absent':
        return Icons.cancel_rounded;
      case 'leave':
        return Icons.event_busy_rounded;
      case 'late':
        return Icons.schedule_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

// ─── Shimmer skeleton ────────────────────────────────────────────────────────

class _AttendanceShimmer extends StatelessWidget {
  final bool isDark;
  const _AttendanceShimmer({required this.isDark});

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

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 22, backgroundColor: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 14,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            Container(
                              height: 20,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              height: 16,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              height: 16,
                              width: 65,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: 110,
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
            ),
          ),
        );
      },
    );
  }
}
