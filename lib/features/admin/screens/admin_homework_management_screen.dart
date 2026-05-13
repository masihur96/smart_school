import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/teacher/screens/homework_details_screen.dart';

import '../../../models/school_models.dart';
import '../../admin/providers/setup_provider.dart';
import '../../admin/providers/teacher_provider.dart';
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
      await context.read<TeachersNotifier>().fetchTeachers();
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
        // backgroundColor: AppColors.primaryAdmin,
        // foregroundColor: Colors.white,
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
          _buildFilterBar(classes, filteredSections, filteredSubjects),
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
                        return _HomeworkCard(
                          homework: hw,
                          onDelete: () => _deleteHomework(hw.id),
                          onEdit: () => _editHomework(hw),
                        );
                      },
                    ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHomeworkSheet(context),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Assign Homework',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    List<ClassRoom> classes,
    List<Section> sections,
    List<Subject> subjects,
  ) {
    return Column(
      children: [
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Class',
                value: _selectedClass,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Classes'),
                  ),
                  ...classes.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
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
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Sections'),
                  ),
                  ...sections.map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ),
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
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Subjects'),
                  ),
                  ...subjects.map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    // color: Colors.grey.shade50,
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
                          color: _selectedDate == null
                              ? Colors.grey.shade600
                              : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
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
        // fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
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
          borderSide: const BorderSide(
            color: AppColors.primaryAdmin,
            width: 1.5,
          ),
        ),
      ),
      value: value,
      items: items,
      onChanged: onChanged,

      icon: const Icon(Icons.keyboard_arrow_down),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  void _showAddHomeworkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddHomeworkSheet(),
    );
  }

  Future<void> _deleteHomework(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Homework'),
        content: const Text('Are you sure you want to delete this homework?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final success = await context
            .read<HomeworkNotifier>()
            .removeAdminHomework(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Homework deleted' : 'Failed to delete homework',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _editHomework(Homework homework) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHomeworkSheet(homework: homework),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final Homework homework;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _HomeworkCard({
    required this.homework,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final due = DateFormat('dd MMM, yyyy').format(homework.dueDate);
    final isPast = homework.dueDate.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeworkDetailsScreen(homeworkId: homework.id),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                    child: const Icon(Icons.assignment_rounded, size: 24),
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
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    onSelected: (val) {
                      if (val == 'edit') {
                        onEdit();
                      } else if (val == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                      Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: $due',
                        style: TextStyle(
                          fontSize: 13,
                          color: isPast
                              ? Colors.red.shade400
                              : Colors.grey.shade700,
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

class _AddHomeworkSheet extends StatefulWidget {
  final Homework? homework;
  const _AddHomeworkSheet({super.key, this.homework});

  @override
  State<_AddHomeworkSheet> createState() => _AddHomeworkSheetState();
}

class _AddHomeworkSheetState extends State<_AddHomeworkSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;
  String? _selectedTeacherId;

  @override
  void initState() {
    super.initState();
    if (widget.homework != null) {
      _titleController.text = widget.homework!.title;
      _descController.text = widget.homework!.description;
      _dueDate = widget.homework!.dueDate;
      _selectedClassId = widget.homework!.classId;
      _selectedSectionId = widget.homework!.sectionId.isEmpty
          ? null
          : widget.homework!.sectionId;
      _selectedSubjectId = widget.homework!.subjectId;
      _selectedTeacherId = widget.homework!.teacherId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryAdmin),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null ||
        _selectedSubjectId == null ||
        _selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select class, subject and teacher'),
        ),
      );
      return;
    }

    final user = context.read<AuthNotifier>().user;
    if (user == null) return;

    final homework = Homework(
      id: widget.homework?.id ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      classId: _selectedClassId!,
      sectionId: _selectedSectionId ?? '',
      subjectId: _selectedSubjectId!,
      teacherId: _selectedTeacherId!,
      schoolId: user.schoolId ?? '',
      dueDate: _dueDate,
      createdAt: widget.homework?.createdAt ?? DateTime.now(),
    );

    final success = widget.homework == null
        ? await context.read<HomeworkNotifier>().submitAdminHomework(homework)
        : await context.read<HomeworkNotifier>().updateAdminHomework(homework);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.homework == null
                  ? 'Homework assigned successfully!'
                  : 'Homework updated successfully!',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save homework')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;
    final teachers = context.watch<TeachersNotifier>().teachers;

    final filteredSections = sections
        .where((s) => s.classId == _selectedClassId)
        .toList();
    final filteredSubjects = subjects
        .where((s) => s.classId == _selectedClassId)
        .toList();

    return Card(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.homework == null
                      ? 'Assign New Homework'
                      : 'Update Homework',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: _inputDeco('Select Class'),
                  value: _selectedClassId,
                  items: classes
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: widget.homework != null
                      ? null
                      : (val) => setState(() {
                          _selectedClassId = val;
                          _selectedSectionId = null;
                          _selectedSubjectId = null;
                        }),
                  validator: (v) => v == null ? 'Class is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _inputDeco('Select Section (Optional)'),
                  value: _selectedSectionId,
                  items: filteredSections
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: widget.homework != null
                      ? null
                      : (val) => setState(() => _selectedSectionId = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _inputDeco('Select Subject'),
                  value: _selectedSubjectId,
                  items: filteredSubjects
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: widget.homework != null
                      ? null
                      : (val) => setState(() => _selectedSubjectId = val),
                  validator: (v) => v == null ? 'Subject is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _inputDeco('Assign to Teacher'),
                  value: _selectedTeacherId,
                  items: teachers
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.user?.id ?? "",
                          child: Text(t.user?.name ?? ""),
                        ),
                      )
                      .toList(),
                  onChanged: widget.homework != null
                      ? null
                      : (val) => setState(() => _selectedTeacherId = val),
                  validator: (v) => v == null ? 'Teacher is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDeco('Homework Title'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: _inputDeco('Description / Instructions'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDueDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDeco('Due Date').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today_rounded),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('dd/MM/yyyy').format(_dueDate),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAdmin,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Assign Homework',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    // fillColor: Colors.grey.shade50,
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
