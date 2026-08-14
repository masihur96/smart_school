import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/models/school_models.dart';

import 'package:smart_school/core/utils/student_attendance_pdf_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/attendance_management_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<AttendanceManagementProvider>();
      if (!provider.isLoading && provider.page < provider.totalPages) {
        provider.fetchStudentAttendance(
          name: _searchController.text,
          startDate: _startDate,
          endDate: _endDate,
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
          subjectId: _selectedSubjectId,
          page: provider.page + 1,
        );
      }
    }
  }

  void _fetchInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<SubjectSetupNotifier>().subjects.isEmpty) {
        context.read<SubjectSetupNotifier>().fetchSchoolData();
      }

      if (context.read<AttendanceManagementProvider>().studentAttendance.isEmpty) {
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
                        items: classProvider.classes.where((c) => c.schoolId == user?.schoolId).toList(),
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
                const SizedBox(height: 8),
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
                      "Total: ${attendanceProvider.total}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child:


            attendanceProvider.isLoading
                ? _AttendanceShimmer(isDark: Theme.of(context).brightness == Brightness.dark)
                : attendanceProvider.error != null
                ? Center(child: Text("Error: ${attendanceProvider.error}"))
                : attendanceProvider.studentAttendance.isEmpty
                ? const Center(child: Text("No records found"))
                : RefreshIndicator(
                    onRefresh: () async => _fetchData(),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          attendanceProvider.studentAttendance.length +
                          (attendanceProvider.isLoading ? 1 : 0),
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        if (index ==
                            attendanceProvider.studentAttendance.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final record =
                            attendanceProvider.studentAttendance[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(
                                record.status,
                              ).withOpacity(0.1),
                              child: Text(
                                record.studentName.isNotEmpty
                                    ? record.studentName[0].toUpperCase()
                                    : "?",
                                style: TextStyle(
                                  color: _getStatusColor(record.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              record.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Class: ${record.classInfo?.name ?? 'N/A'} | Section: ${record.sectionInfo?.name ?? 'N/A'}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Subject: ${record.subjectInfo?.name ?? 'N/A'}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primaryAdmin,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "Date: ${formatDate(record.date)}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
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
                                  record.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                record.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(record.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                      "Teacher",
                                      record.teacherInfo?.name ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      "Time",
                                      "${record.routineInfo?.startTime ?? ''} - ${record.routineInfo?.endTime ?? ''}",
                                    ),
                                    _buildDetailRow(
                                      "Room",
                                      record.routineInfo?.roomNumber ?? 'N/A',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf(BuildContext context) async {
    final attendanceProvider = context.read<AttendanceManagementProvider>();
    final authProvider = context.read<AuthNotifier>();
    final classProvider = context.read<ClassSetupNotifier>();
    final sectionProvider = context.read<SectionSetupNotifier>();
    final subjectProvider = context.read<SubjectSetupNotifier>();

    if (attendanceProvider.studentAttendance.isEmpty) {
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
            .firstWhere((s) => s?.id == _selectedSectionId, orElse: () => null)
            ?.name
        : null;
    final subjectName = _selectedSubjectId != null
        ? subjectProvider.subjects
            .cast<Subject?>()
            .firstWhere((s) => s?.id == _selectedSubjectId, orElse: () => null)
            ?.name
        : null;

    try {
      await StudentAttendancePdfHelper.generateAttendancePdf(
        attendanceList: attendanceProvider.studentAttendance,
        schoolName: authProvider.user?.school?.name ?? "Smart School",
        className: className,
        sectionName: sectionName,
        subjectName: subjectName,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e, stack) {
      log("Error generating PDF: $e\n$stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate PDF: $e")),
      );
    }
  }

  String formatDate(String? utcDate) {
    if (utcDate == null || utcDate.isEmpty) {
      return '--';
    }

    final localDate = DateTime.parse(utcDate).toLocal();

    return DateFormat('dd MMM yyyy, hh:mm a').format(localDate);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(value),
        ],
      ),
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
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      case 'late':
        return Colors.blue;
      default:
        return Colors.grey;
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
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Leading avatar
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Container(
                          height: 14,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Class/Section line
                        Container(
                          height: 12,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subject line
                        Container(
                          height: 11,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Date line
                        Container(
                          height: 10,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Trailing status badge
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
