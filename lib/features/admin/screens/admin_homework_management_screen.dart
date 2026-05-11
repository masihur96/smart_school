import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/teacher/screens/homework_details_screen.dart';

import '../../../models/school_models.dart';
import '../../admin/providers/setup_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teacher/providers/homework_provider.dart';

class AdminHomeworkManagementScreen extends StatefulWidget {
  const AdminHomeworkManagementScreen({super.key});

  @override
  State<AdminHomeworkManagementScreen> createState() =>
      _AdminHomeworkManagementScreenState();
}

class _AdminHomeworkManagementScreenState
    extends State<AdminHomeworkManagementScreen> {
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedSubject;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
    if (schoolId.isNotEmpty) {
      await context.read<ClassSetupNotifier>().fetchSchoolData();
      await context.read<SectionSetupNotifier>().fetchSchoolData();
      await context.read<SubjectSetupNotifier>().fetchSchoolData();
      await _onFetchHomework();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onFetchHomework() async {
    setState(() => _isLoading = true);
    try {
      final schoolId = context.read<AuthNotifier>().user?.schoolId;
      final dateStr = _selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
          : null;

      await context.read<HomeworkNotifier>().fetchAdminHomework(
            classId: _selectedClass,
            sectionId: _selectedSection,
            subjectId: _selectedSubject,
            date: dateStr,
            schoolId: schoolId,
          );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryAdmin,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _onFetchHomework();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeworkNotifier = context.watch<HomeworkNotifier>();
    final homeworkList = homeworkNotifier.homeworkRecords;
    final classes = context.watch<ClassSetupNotifier>().classes;
    final allSections = context.watch<SectionSetupNotifier>().sections;
    final allSubjects = context.watch<SubjectSetupNotifier>().subjects;

    final filteredSections = _selectedClass == null
        ? allSections
        : allSections.where((s) => s.classId == _selectedClass).toList();

    final filteredSubjects = _selectedClass == null
        ? allSubjects
        : allSubjects.where((s) => s.classId == _selectedClass).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Homework Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onFetchHomework,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(
            classes,
            filteredSections,
            filteredSubjects,
          ),
          if (_isLoading)
            const LinearProgressIndicator(color: AppColors.primaryAdmin)
          else
            Expanded(
              child: homeworkList.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: homeworkList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final hw = homeworkList[index];
                        return _HomeworkCard(homework: hw);
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    List<ClassRoom> classes,
    List<Section> sections,
    List<Subject> subjects,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Class',
                  value: _selectedClass,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Classes')),
                    ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedClass = val;
                      _selectedSection = null;
                      _selectedSubject = null;
                    });
                    _onFetchHomework();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Section',
                  value: _selectedSection,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Sections')),
                    ...sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedSection = val);
                    _onFetchHomework();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Subject',
                  value: _selectedSubject,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Subjects')),
                    ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedSubject = val);
                    _onFetchHomework();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null ? Colors.grey.shade600 : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    setState(() => _selectedDate = null);
                    _onFetchHomework();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required ValueChanged<dynamic> onChanged,
  }) {
    return DropdownButtonFormField<dynamic>(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryAdmin, width: 1.5),
        ),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.black, fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No homework found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedClass = null;
                _selectedSection = null;
                _selectedSubject = null;
                _selectedDate = null;
              });
              _onFetchHomework();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAdmin,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final Homework homework;

  const _HomeworkCard({required this.homework});

  @override
  Widget build(BuildContext context) {
    final due = DateFormat('dd MMM, yyyy').format(homework.dueDate);
    final isPast = homework.dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeworkDetailsScreen(homeworkId: homework.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAdmin.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: AppColors.primaryAdmin,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homework.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Teacher: ${homework.teacherInfo?.name ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(isPast),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoTag(
                  Icons.class_outlined,
                  homework.classInfo?.name ?? 'N/A',
                ),
                const SizedBox(width: 8),
                _buildInfoTag(
                  Icons.layers_outlined,
                  homework.sectionInfo?.name ?? 'N/A',
                ),
                const SizedBox(width: 8),
                _buildInfoTag(
                  Icons.book_outlined,
                  homework.subjectInfo?.name ?? 'N/A',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Due: $due',
                      style: TextStyle(
                        fontSize: 13,
                        color: isPast ? Colors.red.shade400 : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Created: ${DateFormat('dd/MM/yy').format(homework.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isPast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPast ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPast ? 'Overdue' : 'Active',
        style: TextStyle(
          color: isPast ? Colors.red.shade700 : Colors.green.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
