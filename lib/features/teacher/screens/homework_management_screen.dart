import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/teacher/screens/homework_details_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';

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
  String? _selectedSection;
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
      final classProvider = context.read<ClassSetupNotifier>();
      if (classProvider.classes.isEmpty) await classProvider.fetchSchoolData();
      
      final sectionProvider = context.read<SectionSetupNotifier>();
      if (sectionProvider.sections.isEmpty) await sectionProvider.fetchSchoolData();
      
      final subjectProvider = context.read<SubjectSetupNotifier>();
      if (subjectProvider.subjects.isEmpty) await subjectProvider.fetchSchoolData();
      
      final homeworkNotifier = context.read<HomeworkNotifier>();
      if (homeworkNotifier.homeworkRecords.isEmpty) {
        await _onFetchHomework();
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onFetchHomework() async {
    setState(() => _isLoading = true);
    try {
      await context.read<HomeworkNotifier>().fetchHomework(
        classId: _selectedClass,
        sectionId: _selectedSection,
        subjectId: _selectedSubject,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.watch<AuthNotifier>().user;
    if (currentUser == null) {
      return Scaffold(body: Center(child: Text(l10n.pleaseLogin)));
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
              backgroundColor: AppColors.primaryTeacher,
              foregroundColor: Colors.white,
              elevation: 0,
            ),

      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // color: Colors.white,
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
                      child: DropdownButtonFormField<String?>(
                        decoration: _inputDeco('Class'),
                        value: _selectedClass,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.allClasses),
                          ),
                          ...classes.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
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
                      child: DropdownButtonFormField<String?>(
                        decoration: _inputDeco('Section'),
                        value: _selectedSection,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.allSections),
                          ),
                          ...context
                              .read<SectionSetupNotifier>()
                              .sections
                              .where((s) => s.classId == _selectedClass)
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedSection = val;
                          });
                          _onFetchHomework();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  decoration: _inputDeco('Subject'),
                  value: _selectedSubject,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.allSubjects),
                    ),
                    ...filteredSubjects.map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedSubject = val);
                    _onFetchHomework();
                  },
                ),
              ],
            ),
          ),
          if (_isLoading)
            Expanded(child: _buildShimmerLoading())
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
                            className: classObj.name,
                            subjectName: subject.name,
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
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _showAddSheet(context),
      //   backgroundColor: AppColors.primaryTeacher,
      //   foregroundColor: Colors.white,
      //   icon: const Icon(Icons.add),
      //   label: const Text(
      //     'Add Homework',
      //     style: TextStyle(fontWeight: FontWeight.bold),
      //   ),
      // ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.zero,
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 120,
                          height: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          height: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 80,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.more_vert, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        );
      },
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteHomework),
        content: Text(l10n.deleteHomeworkConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
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
                    SnackBar(content: Text(l10n.failedToDeleteHomework)),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    filled: true,

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
  final String className;
  final String subjectName;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HomeworkCard({
    required this.homework,
    required this.className,
    required this.subjectName,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = homework.dueDate.isBefore(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onView,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeacher.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            size: 16,
                            color: AppColors.primaryTeacher,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              homework.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: homework.description.isEmpty ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_vert, color: Colors.grey.shade500, size: 22),
                          onSelected: (val) {
                            if (val == 'view') {
                              onView();
                            } else if (val == 'edit') {
                              onEdit();
                            } else if (val == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (_) {
                            final l10n = AppLocalizations.of(context)!;
                            return [
                              PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    const Icon(Icons.visibility_outlined, size: 18),
                                    const SizedBox(width: 8),
                                    Text(l10n.view),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 18),
                                    const SizedBox(width: 8),
                                    Text(l10n.edit),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      homework.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.class_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              className,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subjectName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOverdue ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOverdue ? Colors.red.shade100 : Colors.green.shade100,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: isOverdue ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM, EEEE').format(homework.dueDate),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOverdue ? Colors.red.shade700 : Colors.green.shade700,
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

    return Card(
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
                    Text('Due Date', style: TextStyle(fontSize: 11)),
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                ),
              ),
              child: Text(
                homework.description.isNotEmpty
                    ? homework.description
                    : 'No description provided.',
                style: TextStyle(fontSize: 14, height: 1.5),
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
