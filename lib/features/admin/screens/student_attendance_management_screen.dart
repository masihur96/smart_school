import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/models/school_models.dart';

import '../providers/attendance_management_provider.dart';

class StudentAttendanceManagementScreen extends StatefulWidget {
  const StudentAttendanceManagementScreen({super.key});

  @override
  State<StudentAttendanceManagementScreen> createState() =>
      _StudentAttendanceManagementScreenState();
}

class _StudentAttendanceManagementScreenState
    extends State<StudentAttendanceManagementScreen> {
  DateTime? _selectedDate;
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
          date: _selectedDate,
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
      context.read<ClassSetupNotifier>().fetchSchoolData();
      context.read<SectionSetupNotifier>().fetchSchoolData();
      context.read<SubjectSetupNotifier>().fetchSchoolData();

      _fetchData();
    });
  }

  void _fetchData({int page = 1}) {
    context.read<AttendanceManagementProvider>().fetchStudentAttendance(
          name: _searchController.text,
          date: _selectedDate,
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
          subjectId: _selectedSubjectId,
          page: page,
        );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
    final attendanceProvider = context.watch<AttendanceManagementProvider>();
    final classProvider = context.watch<ClassSetupNotifier>();
    final sectionProvider = context.watch<SectionSetupNotifier>();
    final subjectProvider = context.watch<SubjectSetupNotifier>();

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
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
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
                          color: _selectedDate != null
                              ? AppColors.primaryAdmin
                              : AppColors.primaryAdmin.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: _selectedDate != null
                              ? Colors.white
                              : AppColors.primaryAdmin,
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
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
                        items: classProvider.classes,
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
                      _selectedDate == null
                          ? "All Dates"
                          : "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      "Total: ${attendanceProvider.total}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: attendanceProvider.studentAttendance.isEmpty &&
                    attendanceProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : attendanceProvider.error != null
                    ? Center(child: Text("Error: ${attendanceProvider.error}"))
                    : attendanceProvider.studentAttendance.isEmpty
                        ? const Center(child: Text("No records found"))
                        : RefreshIndicator(
                            onRefresh: () async => _fetchData(),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: attendanceProvider
                                      .studentAttendance.length +
                                  (attendanceProvider.isLoading ? 1 : 0),
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                if (index ==
                                    attendanceProvider
                                        .studentAttendance.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final record = attendanceProvider
                                    .studentAttendance[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ExpansionTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _getStatusColor(record.status)
                                              .withOpacity(0.1),
                                      child: Text(
                                        record.studentName.isNotEmpty
                                            ? record.studentName[0]
                                                .toUpperCase()
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
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          "Date: ${record.date}",
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
                                        color: _getStatusColor(record.status)
                                            .withOpacity(0.1),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildDetailRow(
                                                "Teacher",
                                                record.teacherInfo?.name ??
                                                    'N/A'),
                                            _buildDetailRow(
                                                "Time",
                                                "${record.routineInfo?.startTime ?? ''} - ${record.routineInfo?.endTime ?? ''}"),
                                            _buildDetailRow(
                                                "Room",
                                                record.routineInfo
                                                        ?.roomNumber ??
                                                    'N/A'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text("$label: ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
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
                child: Text(itemLabel(item),
                    style: const TextStyle(fontSize: 12)),
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
