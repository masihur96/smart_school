import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/school_models.dart' hide Teacher;
import '../../../models/teacher_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/teacher_provider.dart';

// Local model for a single academic assignment draft
class _AssignmentDraft {
  String? id;
  String? classId;
  String? subjectId;
  String? examinerId;
  DateTime date;
  String? syllabus;

  _AssignmentDraft({
    this.id,
    this.classId,
    this.subjectId,
    this.examinerId,
    DateTime? date,
    this.syllabus,
  }) : date = date ?? DateTime.now().add(const Duration(days: 1));
}

class AddEditExamScreen extends StatefulWidget {
  final Exam? exam;
  const AddEditExamScreen({super.key, this.exam});

  @override
  State<AddEditExamScreen> createState() => _AddEditExamScreenState();
}

class _AddEditExamScreenState extends State<AddEditExamScreen> {
  int _currentStep = 0;

  // Step 1 fields
  final _step1Key = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  // Step 2 fields
  final List<_AssignmentDraft> _assignments = [];

  bool get isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.exam!.name;
      _descController.text = widget.exam!.description ?? '';
      _startDate = widget.exam!.startDate ?? DateTime.now();
      _endDate = widget.exam!.endDate ?? DateTime.now();

      for (final a in widget.exam!.assignments) {
        _assignments.add(
          _AssignmentDraft(
            id: a.id,
            classId: a.classId,
            subjectId: a.subjectId,
            examinerId: a.examinerId,
            date: a.date,
            syllabus: a.syllabus,
          ),
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeachersNotifier>().fetchTeachers();
      final schoolId = context.read<AuthNotifier>().user?.schoolId;
      if (schoolId != null) {
        context.read<ClassSetupNotifier>().fetchClasses(schoolId);
        context.read<SubjectSetupNotifier>().fetchSubjects(schoolId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Date picker helper ─────────────────────────────────────────────────────
  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now().subtract(const Duration(days: 365)),
    lastDate: DateTime.now().add(const Duration(days: 730)),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Colors.purple,
          onPrimary: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      child: child!,
    ),
  );

  // ── STEP 1: Exam details ───────────────────────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        children: [
          _field(
            controller: _nameController,
            label: 'Exam Name',
            hint: 'e.g. Final Exam 2025',
            icon: Icons.edit_note,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _descController,
            label: 'Description (optional)',
            hint: 'e.g. End of year examination',
            icon: Icons.description_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          _dateTile(
            label: 'Start Date',
            icon: Icons.event,
            value: _startDate,
            onTap: () async {
              final d = await _pickDate(_startDate);
              if (d != null) setState(() => _startDate = d);
            },
          ),
          const SizedBox(height: 14),
          _dateTile(
            label: 'End Date',
            icon: Icons.event_available,
            value: _endDate,
            onTap: () async {
              final d = await _pickDate(_endDate);
              if (d != null) setState(() => _endDate = d);
            },
          ),
        ],
      ),
    );
  }

  // ── STEP 2: Assignments ────────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.purple.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${DateFormat('MMM dd').format(_startDate)} – ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                    if (_descController.text.isNotEmpty)
                      Text(
                        _descController.text,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Academic Assignments (${_assignments.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            TextButton.icon(
              onPressed: _addAssignmentSheet,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: Colors.purple),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_assignments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 40,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Text(
                  'No assignments yet.\nTap "Add" to assign a class, subject & examiner.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ..._assignments.asMap().entries.map((e) {
            final i = e.key;
            final a = e.value;
            return _AssignmentCard(
              index: i,
              draft: a,
              onEdit: () => _addAssignmentSheet(index: i),
              onDelete: () => setState(() => _assignments.removeAt(i)),
            );
          }),
      ],
    );
  }

  // ── Add/Edit assignment bottom sheet ────────────────────────────────────
  void _addAssignmentSheet({int? index}) {
    final classes = context.read<ClassSetupNotifier>().classes;
    final allSubjects = context.read<SubjectSetupNotifier>().subjects;
    final teachers = context.read<TeachersNotifier>().teachers;

    final editing = index != null;
    final draft = editing ? _assignments[index] : _AssignmentDraft();

    String? id = draft.id;
    String? classId = draft.classId;
    String? subjectId = draft.subjectId;
    String? examinerId = draft.examinerId;
    DateTime date = draft.date;
    String? syllabus = draft.syllabus;

    final syllabusController = TextEditingController(text: syllabus);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          builder: (_, scrollCtr) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Icon(
                        editing ? Icons.edit : Icons.add_circle,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        editing ? 'Edit Assignment' : 'Add Assignment',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollCtr,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Class dropdown
                      DropdownButtonFormField<String>(
                        decoration: _dropDeco('Class', Icons.class_outlined),
                        value: classId,
                        items: classes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setBS(() {
                          classId = v;
                          subjectId = null;
                        }),
                      ),
                      const SizedBox(height: 14),
                      // Subject dropdown (filtered by class)
                      DropdownButtonFormField<String>(
                        decoration: _dropDeco('Subject', Icons.book_outlined),
                        value: subjectId,
                        items: allSubjects
                            .where(
                              (s) => classId == null || s.classId == classId,
                            )
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setBS(() => subjectId = v),
                      ),
                      const SizedBox(height: 14),
                      // Examiner dropdown
                      DropdownButtonFormField<String>(
                        decoration: _dropDeco(
                          'Examiner / Teacher',
                          Icons.person_outline,
                        ),
                        value: examinerId,
                        items: teachers
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.userId,
                                child: Text(t.user?.name ?? 'Unknown'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setBS(() => examinerId = v),
                      ),
                      const SizedBox(height: 14),
                      // Date picker
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final d = await _pickDate(date);
                          if (d != null) setBS(() => date = d);
                        },
                        child: InputDecorator(
                          decoration: _dropDeco(
                            'Exam Date',
                            Icons.calendar_today,
                          ),
                          child: Text(
                            DateFormat('EEEE, MMM dd, yyyy').format(date),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Syllabus
                      TextFormField(
                        controller: syllabusController,
                        decoration: _dropDeco(
                          'Syllabus (e.g. Chapter 1-5)',
                          Icons.book_outlined,
                        ),
                        onChanged: (v) => syllabus = v,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              (classId == null ||
                                  subjectId == null ||
                                  examinerId == null)
                              ? null
                              : () {
                                  setState(() {
                                    if (editing) {
                                      _assignments[index]
                                        ..id = id
                                        ..classId = classId
                                        ..subjectId = subjectId
                                        ..examinerId = examinerId
                                        ..date = date
                                        ..syllabus = syllabus;
                                    } else {
                                      _assignments.add(
                                        _AssignmentDraft(
                                          id: id,
                                          classId: classId,
                                          subjectId: subjectId,
                                          examinerId: examinerId,
                                          date: date,
                                          syllabus: syllabus,
                                        ),
                                      );
                                    }
                                  });
                                  Navigator.pop(ctx);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            editing ? 'Save Changes' : 'Add Assignment',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dropDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.purple),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );

  // ── Save / Submit ──────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one academic assignment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final examsNotifier = context.read<ExamsNotifier>();
    try {
      final List<Map<String, dynamic>> assignmentsList = _assignments
          .where(
            (a) =>
                a.classId != null &&
                a.classId!.trim().isNotEmpty &&
                a.subjectId != null &&
                a.subjectId!.trim().isNotEmpty &&
                a.examinerId != null &&
                a.examinerId!.trim().isNotEmpty,
          )
          .map(
            (a) => {
              if (a.id != null && a.id!.isNotEmpty) 'id': a.id,
              'class_uid': a.classId!,
              'subject_uid': a.subjectId!,
              'examiner_uid': a.examinerId!,
              'date': a.date,
              'syllabus': a.syllabus,
            },
          )
          .toList();

      if (isEditing) {
        await examsNotifier.updateExamOnAPI(
          examId: widget.exam!.id,
          examName: _nameController.text.trim(),
          description: _descController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          assignments: assignmentsList,
        );
      } else {
        await examsNotifier.createExamWithAssignments(
          examName: _nameController.text.trim(),
          description: _descController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          assignments: assignmentsList,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exam "${_nameController.text.trim()}" saved successfully.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      log('Error saving exam: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final examsNotifier = context.watch<ExamsNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Exam' : 'Create Exam'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.purple),
        ),
        child: Stepper(
          currentStep: _currentStep,
          type: StepperType.horizontal,
          elevation: 0,
          onStepTapped: (i) {
            if (i == 1 && !(_step1Key.currentState?.validate() ?? false))
              return;
            setState(() => _currentStep = i);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  if (_currentStep == 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_step1Key.currentState!.validate()) {
                            if (_endDate.isBefore(_startDate)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'End date must be after start date.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            setState(() => _currentStep = 1);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Next: Add Assignments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep == 1) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep = 0),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.purple),
                          foregroundColor: Colors.purple,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: examsNotifier.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: examsNotifier.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Create Exam (${_assignments.length})',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Details'),
              subtitle: const Text('Name & dates'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildStep1(),
            ),
            Step(
              title: const Text('Assignments'),
              subtitle: Text('${_assignments.length} added'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildStep2(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required IconData icon,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.purple),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text(
          DateFormat('EEEE, MMM dd, yyyy').format(value),
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}

// ── Assignment card widget ────────────────────────────────────────────────────
class _AssignmentCard extends StatelessWidget {
  final int index;
  final _AssignmentDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssignmentCard({
    required this.index,
    required this.draft,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;
    final teachers = context.watch<TeachersNotifier>().teachers;

    final className = classes
        .firstWhere(
          (c) => c.id == draft.classId,
          orElse: () => ClassRoom(id: '', name: 'Unknown'),
        )
        .name;
    final subjectName = subjects
        .firstWhere(
          (s) => s.id == draft.subjectId,
          orElse: () => Subject(id: '', name: 'Unknown'),
        )
        .name;
    final teacherName =
        teachers
            .firstWhere(
              (t) => t.userId == draft.examinerId,
              orElse: () => Teacher(userId: ''),
            )
            .user
            ?.name ??
        'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade50,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '$className  •  $subjectName',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Examiner: $teacherName',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(
              DateFormat('MMM dd, yyyy').format(draft.date),
              style: TextStyle(
                color: Colors.purple.shade300,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (draft.syllabus != null && draft.syllabus!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Syllabus: ${draft.syllabus}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
