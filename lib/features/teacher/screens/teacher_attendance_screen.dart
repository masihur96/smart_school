import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/teacher/providers/attendance_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/period_attendance_model.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final bool hideAppBar;
  const TeacherAttendanceScreen({super.key, this.hideAppBar = false});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
      final provider = context.read<AttendanceNotifier>();
      if (provider.periodAttendanceRecords.isEmpty) {
        _fetchData();
      }
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
      final classProvider = context.read<ClassSetupNotifier>();
      if (classProvider.classes.isEmpty) classProvider.fetchSchoolData();

      final sectionProvider = context.read<SectionSetupNotifier>();
      if (sectionProvider.sections.isEmpty) sectionProvider.fetchSchoolData();

      final subjectProvider = context.read<SubjectSetupNotifier>();
      if (subjectProvider.subjects.isEmpty) {
        subjectProvider.fetchSubjects(schoolId);
      }
    }
  }

  Future<void> _fetchData({int page = 1}) async {
    await context.read<AttendanceNotifier>().fetchPeriodAttendance(
      studentName: _searchController.text,
      startDate: _startDate,
      endDate: _endDate,
      classId: _selectedClassId,
      sectionId: _selectedSectionId,
      subjectId: _selectedSubjectId,
      page: page,
    );
  }

  bool get _hasActiveFilters =>
      _selectedClassId != null ||
      _selectedSectionId != null ||
      _selectedSubjectId != null ||
      _startDate != null ||
      _endDate != null ||
      _searchController.text.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedClassId = null;
      _selectedSectionId = null;
      _selectedSubjectId = null;
      _startDate = null;
      _endDate = null;
    });
    _fetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text(
                l10n.attendanceRecordsTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.primaryTeacher,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                if (_hasActiveFilters)
                  IconButton(
                    icon: const Icon(Icons.filter_alt_off),
                    tooltip: 'Clear Filters',
                    onPressed: _clearFilters,
                  ),
              ],
            ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: Consumer<AttendanceNotifier>(
              builder: (context, provider, child) {
                if (provider.isLoading &&
                    provider.periodAttendanceRecords.isEmpty) {
                  return _buildShimmerLoading();
                }

                if (provider.periodAttendanceRecords.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => _fetchData(page: 1),
                  color: AppColors.primaryTeacher,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount:
                        provider.periodAttendanceRecords.length +
                        (provider.page < provider.totalPages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < provider.periodAttendanceRecords.length) {
                        final record = provider.periodAttendanceRecords[index];
                        return _AttendanceRecordCard(record: record);
                      } else {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 150,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
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

  Widget _buildFilterSection() {
    final classProvider = context.watch<ClassSetupNotifier>();
    final sectionProvider = context.watch<SectionSetupNotifier>();
    final subjectProvider = context.watch<SubjectSetupNotifier>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.primaryTeacher,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeacher.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _fetchData(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by student name...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    color: Colors.grey.shade500,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _fetchData();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),

            if (_isFilterExpanded) ...[
              const SizedBox(height: 16),
              // Dropdowns Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown<String>(
                      hint: 'Class',
                      value: _selectedClassId,
                      icon: Icons.class_outlined,
                      items: classProvider.classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown<String>(
                      hint: 'Section',
                      value: _selectedSectionId,
                      icon: Icons.groups_outlined,
                      items: sectionProvider.sections
                          .where((s) => s.classId == _selectedClassId)
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedSectionId = value);
                        _fetchData();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildDateRangePicker(),
                ],
              ),
            ],

            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isFilterExpanded = !_isFilterExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isFilterExpanded ? 'Hide Filters' : 'Show Filters',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isFilterExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    final hasDate = _startDate != null && _endDate != null;
    return GestureDetector(
      onTap: _pickDateRange,
      child: Container(
        height: 48,
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_outlined,
              size: 20,
              color: hasDate ? AppColors.primaryTeacher : Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasDate
                    ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                    : 'Date Range',
                style: TextStyle(
                  color: hasDate ? Colors.black87 : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: hasDate ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _fetchData();
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: value != null
                ? AppColors.primaryTeacher
                : Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(
                  hint,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.expand_more,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                items: items,
                onChanged: onChanged,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
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
              surface: Colors.white,
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.doc_text_search,
                size: 80,
                color: Colors.blue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Attendance Records',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any records matching\nyour current filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeacher,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ],
        ),
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
    final statusIcon = _getStatusIcon(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(color: statusColor),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  childrenPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        record.studentName.isNotEmpty
                            ? record.studentName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    record.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                record.subjectInfo?.name ?? "Subject",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 12,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    record.status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(DateTime.parse(record.date)),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.class_outlined,
                            'Class & Section',
                            '${record.classInfo?.name ?? "--"} - ${record.sectionInfo?.name ?? "--"}',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.person_outline,
                            'Teacher',
                            record.teacherInfo?.name ?? '--',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.schedule_outlined,
                            'Routine',
                            '${record.routineInfo?.startTime ?? "--"} - ${record.routineInfo?.endTime ?? "--"}',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.calendar_today_outlined,
                            'Day',
                            record.routineInfo?.day ?? '--',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, size: 16, color: Colors.blueGrey),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green.shade600;
      case 'absent':
        return Colors.red.shade500;
      case 'late':
        return Colors.orange.shade600;
      case 'leave':
        return Colors.blue.shade500;
      case 'half_day':
        return Colors.purple.shade500;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time_filled;
      case 'leave':
        return Icons.directions_run;
      case 'half_day':
        return Icons.timelapse;
      default:
        return Icons.info;
    }
  }
}
