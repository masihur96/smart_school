import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/teacher/providers/attendance_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/period_attendance_model.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final bool hideAppBar;
  const TeacherAttendanceScreen({super.key, this.hideAppBar = false});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
      _fetchData();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<AttendanceNotifier>();
      if (!provider.isLoading && provider.page < provider.totalPages) {
        _fetchData(page: provider.page + 1);
      }
    }
  }

  Future<void> _fetchInitialData() async {
    final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
    if (schoolId.isNotEmpty) {
      context.read<ClassSetupNotifier>().fetchSchoolData();
      context.read<SectionSetupNotifier>().fetchSchoolData();
      context.read<SubjectSetupNotifier>().fetchSubjects(schoolId);
    }
  }

  void _fetchData({int page = 1}) {
    context.read<AttendanceNotifier>().fetchPeriodAttendance(
          studentName: _searchController.text,
          startDate: _startDate,
          endDate: _endDate,
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
          subjectId: _selectedSubjectId,
          page: page,
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('Attendance Records'),
              backgroundColor: AppColors.primaryTeacher,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: Consumer<AttendanceNotifier>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.periodAttendanceRecords.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.periodAttendanceRecords.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.periodAttendanceRecords.length +
                      (provider.page < provider.totalPages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < provider.periodAttendanceRecords.length) {
                      final record = provider.periodAttendanceRecords[index];
                      return _AttendanceRecordCard(record: record);
                    } else {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final classProvider = context.watch<ClassSetupNotifier>();
    final sectionProvider = context.watch<SectionSetupNotifier>();
    final subjectProvider = context.watch<SubjectSetupNotifier>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primaryTeacher,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _fetchData(),
            decoration: InputDecoration(
              hintText: 'Search student name...',
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          // Dropdowns Row 1
          Row(
            children: [
              Expanded(
                child: _buildDropdown<String>(
                  hint: 'Class',
                  value: _selectedClassId,
                  items: classProvider.classes
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClassId = value;
                      _selectedSectionId = null;
                      _selectedSubjectId = null;
                    });
                    _fetchData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown<String>(
                  hint: 'Section',
                  value: _selectedSectionId,
                  items: sectionProvider.sections
                      .where((s) => s.classId == _selectedClassId)
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedSectionId = value);
                    _fetchData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Dropdowns Row 2
          Row(
            children: [
              Expanded(
                child: _buildDropdown<String>(
                  hint: 'Subject',
                  value: _selectedSubjectId,
                  items: subjectProvider.subjects
                      .where((s) => s.classId == _selectedClassId || _selectedClassId == null)
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedSubjectId = value);
                    _fetchData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (_startDate == null || _endDate == null)
                                ? 'Date Range'
                                : '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}',
                            style: TextStyle(
                              color: (_startDate == null) ? Colors.grey[600] : Colors.black,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_startDate != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                              });
                              _fetchData();
                            },
                            child: const Icon(Icons.close, size: 16, color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryTeacher,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text('Try adjusting your filters', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  final PeriodAttendance record;
  const _AttendanceRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                record.studentName.isNotEmpty ? record.studentName[0].toUpperCase() : '?',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          title: Text(
            record.studentName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${record.classInfo?.name ?? "Class"} - ${record.sectionInfo?.name ?? "Section"}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(DateTime.parse(record.date)),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  _buildDetailRow(Icons.book, 'Subject', record.subjectInfo?.name ?? '--'),
                  _buildDetailRow(Icons.person, 'Teacher', record.teacherInfo?.name ?? '--'),
                  _buildDetailRow(Icons.access_time, 'Routine',
                      '${record.routineInfo?.startTime ?? "--"} - ${record.routineInfo?.endTime ?? "--"}'),
                  _buildDetailRow(Icons.calendar_today, 'Day', record.routineInfo?.day ?? '--'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'leave':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
