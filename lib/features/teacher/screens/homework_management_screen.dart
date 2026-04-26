import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/teacher/screens/homework_details_screen.dart';

import '../../../models/school_models.dart';
import '../../admin/providers/setup_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/homework_provider.dart';

class HomeworkManagementScreen extends StatefulWidget {
  final bool hideAppBar;
  const HomeworkManagementScreen({super.key, this.hideAppBar = false});

  @override
  State<HomeworkManagementScreen> createState() =>
      _HomeworkManagementScreenState();
}

class _HomeworkManagementScreenState extends State<HomeworkManagementScreen> {
  String? _selectedClass;
  String? _selectedSubject;
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
      await context.read<HomeworkNotifier>().fetchHomework(
        classId: _selectedClass,
        subjectId: _selectedSubject,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthNotifier>().user;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    final homeworkNotifier = context.watch<HomeworkNotifier>();
    final homeworkList =
        homeworkNotifier.homeworkRecords; // Use all fetched records
    final classes = context.watch<ClassSetupNotifier>().classes;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

    final filteredSubjects = _selectedClass == null
        ? subjects
        : subjects.where((s) => s.classId == _selectedClass).toList();

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text(
                'My Homeworks',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      backgroundColor: const Color(0xFFF5F3FF),
      body: Column(
        children: [
          // Filter Bar
          Container(
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
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: _inputDeco('Class'),
                    value: _selectedClass,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ...classes.map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedClass = val;
                        _selectedSubject = null;
                      });
                      _onFetchHomework();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: _inputDeco('Subject'),
                    value: _selectedSubject,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Subjects'),
                      ),
                      ...filteredSubjects.map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedSubject = val);
                      _onFetchHomework();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator()
          else
            Expanded(
              child: homeworkList.isEmpty
                  ? const _EmptyState(
                      icon: Icons.assignment_outlined,
                      message: 'No homeworks found.\nTap + to add one.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: homeworkList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final hw = homeworkList[index];
                        final subject = subjects.firstWhere(
                          (s) => s.id == hw.subjectId,
                          orElse: () =>
                              Subject(id: '', name: 'Unknown Subject'),
                        );
                        final classObj = classes.firstWhere(
                          (c) => c.id == hw.classId,
                          orElse: () => ClassRoom(id: '', name: 'Unknown'),
                        );

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    HomeworkDetailsScreen(homeworkId: hw.id),
                              ),
                            );
                          },
                          child: _HomeworkCard(
                            homework: hw,
                            subjectName: '${classObj.name} - ${subject.name}',
                            onView: () =>
                                _showViewSheet(context, hw, subject.name),
                            onEdit: () => _showEditSheet(context, hw),
                            onDelete: () => _confirmDelete(context, hw.id),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Homework',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddHomeworkSheet(),
    );
  }

  void _showEditSheet(BuildContext context, Homework homework) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHomeworkSheet(homework: homework),
    );
  }

  void _showViewSheet(
    BuildContext context,
    Homework homework,
    String subjectName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ViewHomeworkSheet(homework: homework, subjectName: subjectName),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Homework'),
        content: const Text('Are you sure you want to delete this homework?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context
                  .read<HomeworkNotifier>()
                  .removeHomework(id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete homework')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF5F3FF),
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
      borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Homework Card
// ─────────────────────────────────────────────────────────────────────────────

class _HomeworkCard extends StatelessWidget {
  final Homework homework;
  final String subjectName;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HomeworkCard({
    required this.homework,
    required this.subjectName,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final due = DateFormat('dd/MM/yyyy').format(homework.dueDate);
    final isPast = homework.dueDate.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_rounded,
                color: Colors.white,
                size: 22,
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
                      fontSize: 15,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subjectName,
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (homework.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      homework.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 14,
                        color: isPast ? Colors.red[400] : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: $due',
                        style: TextStyle(
                          fontSize: 11,
                          color: isPast ? Colors.red[400] : Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              onSelected: (val) {
                if (val == 'view') {
                  onView();
                } else if (val == 'edit') {
                  onEdit();
                } else if (val == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('View'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Homework Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddHomeworkSheet extends StatefulWidget {
  final Homework? homework;

  const _AddHomeworkSheet({this.homework});

  @override
  State<_AddHomeworkSheet> createState() => _AddHomeworkSheetState();
}

class _AddHomeworkSheetState extends State<_AddHomeworkSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late DateTime _dueDate;
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.homework?.title ?? '',
    );
    _descController = TextEditingController(
      text: widget.homework?.description ?? '',
    );
    _dueDate =
        widget.homework?.dueDate ?? DateTime.now().add(const Duration(days: 1));

    if (widget.homework != null) {
      _selectedClassId = widget.homework!.classId;
      _selectedSectionId = widget.homework!.sectionId;
      _selectedSubjectId = widget.homework!.subjectId;
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF7C3AED)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null || _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class and subject')),
      );
      return;
    }

    final user = context.read<AuthNotifier>().user;
    if (user == null) return;

    final homework = Homework(
      id:
          widget.homework?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      classId: _selectedClassId!,
      sectionId: _selectedSectionId ?? '',
      subjectId: _selectedSubjectId!,
      teacherId: widget.homework?.teacherId ?? user.id,
      schoolId: user.schoolId ?? '',
      dueDate: _dueDate,
      createdAt: widget.homework?.createdAt ?? DateTime.now(),
    );

    final bool success;
    if (widget.homework == null) {
      success = await context.read<HomeworkNotifier>().submitHomework(homework);
    } else {
      success = await context.read<HomeworkNotifier>().updateHomework(homework);
    }

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

    final filteredSections = sections
        .where((s) => s.classId == _selectedClassId)
        .toList();
    final filteredSubjects = subjects
        .where((s) => s.classId == _selectedClassId)
        .toList();

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    widget.homework == null ? 'Add Homework' : 'Edit Homework',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  widget.homework == null
                      ? DropdownButtonFormField<String>(
                          decoration: _inputDeco('Class'),
                          value: _selectedClassId,
                          items: classes
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(() {
                            _selectedClassId = val;
                            _selectedSectionId = null;
                            _selectedSubjectId = null;
                          }),
                          validator: (v) =>
                              v == null ? 'Class is required' : null,
                        )
                      : SizedBox(),
                  const SizedBox(height: 12),
                  widget.homework == null
                      ? DropdownButtonFormField<String>(
                          decoration: _inputDeco('Section (optional)'),
                          value: _selectedSectionId,
                          items: filteredSections
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedSectionId = val),
                        )
                      : SizedBox(),
                  const SizedBox(height: 12),
                  widget.homework == null
                      ? DropdownButtonFormField<String>(
                          decoration: _inputDeco('Subject'),
                          value: _selectedSubjectId,
                          items: filteredSubjects
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedSubjectId = val),
                          validator: (v) =>
                              v == null ? 'Subject is required' : null,
                        )
                      : SizedBox(),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDeco('Homework Title'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: _inputDeco('Description (optional)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        widget.homework == null ? 'Assign' : 'Update',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF5F3FF),
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
      borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// View Homework Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ViewHomeworkSheet extends StatelessWidget {
  final Homework homework;
  final String subjectName;

  const _ViewHomeworkSheet({required this.homework, required this.subjectName});

  @override
  Widget build(BuildContext context) {
    final due = DateFormat('dd/MM/yyyy').format(homework.dueDate);
    final isPast = homework.dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subjectName,
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            homework.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B4B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: isPast ? Colors.red : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due Date',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  Text(
                    due,
                    style: TextStyle(
                      color: isPast ? Colors.red : const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
              ),
            ),
            child: Text(
              homework.description.isNotEmpty
                  ? homework.description
                  : 'No description provided.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State widget
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: const Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
