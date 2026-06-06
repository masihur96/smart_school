import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/teacher_model.dart';

import '../../../models/school_models.dart' hide Teacher;
import '../providers/exam_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';
import '../providers/teacher_provider.dart';
import 'add_edit_exam_screen.dart';
import 'exam_view_screen.dart';

class ExamManagementScreen extends StatefulWidget {
  final bool hideAppBar;
  const ExamManagementScreen({super.key, this.hideAppBar = false});

  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  String? _selectedClass;
  String? _selectedSubject;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeachersNotifier>().fetchTeachers();
      context.read<StudentsNotifier>().fetchStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final examsNotifier = context.watch<ExamsNotifier>();
    final allExams = examsNotifier.state;
    final classes = context.watch<ClassSetupNotifier>().classes;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

    // Apply filters
    final exams = allExams.where((exam) {
      final matchesClass =
          _selectedClass == null ||
          exam.assignments.any((a) => a.classId == _selectedClass);
      final matchesSubject =
          _selectedSubject == null ||
          exam.assignments.any((a) => a.subjectId == _selectedSubject);
      final matchesStatus =
          _selectedStatus == 'All' ||
          (_selectedStatus == 'Published' && exam.isPublished) ||
          (_selectedStatus == 'Unpublished' && !exam.isPublished);
      return matchesClass && matchesSubject && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context)!.examManagement),
              elevation: 0,
              backgroundColor: AppColors.primaryAdmin,
              foregroundColor: AppColors.white,
            ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.publishStatus,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedStatus,
                  items: [
                    DropdownMenuItem(value: 'All', child: Text(AppLocalizations.of(context)!.all)),
                    DropdownMenuItem(value: 'Published', child: Text(AppLocalizations.of(context)!.publishedOption)),
                    DropdownMenuItem(value: 'Unpublished', child: Text(AppLocalizations.of(context)!.unpublishedOption)),
                  ],
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
              ],
            ),
          ),

          // Exam List
          Expanded(
            child: examsNotifier.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  )
                : exams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noExamsFound,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exams.length,
                    itemBuilder: (context, index) {
                      final exam = exams[index];
                      final assignmentsCount = exam.assignments.length;
                      String subtitleText =
                          AppLocalizations.of(context)!.assignmentCountLabel(assignmentsCount);
                      if (assignmentsCount > 0) {
                        final firstClass = classes
                            .firstWhere(
                              (c) => c.id == exam.assignments.first.classId,
                              orElse: () => ClassRoom(id: '', name: ''),
                            )
                            .name;
                        final firstSubj = subjects
                            .firstWhere(
                              (s) => s.id == exam.assignments.first.subjectId,
                              orElse: () => Subject(id: '', name: ''),
                            )
                            .name;
                        if (firstClass.isNotEmpty && firstSubj.isNotEmpty) {
                          subtitleText += ' • ${AppLocalizations.of(context)!.egLabel} $firstClass - $firstSubj';
                        }
                      }

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.purple.shade300,
                                              Colors.purple.shade600,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.assignment,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        exam.isPublished
                                            ? AppLocalizations.of(context)!.publishedOption
                                            : AppLocalizations.of(context)!.draft,
                                        style: TextStyle(
                                          color: exam.isPublished
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              exam.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitleText,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 14,
                                              // color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${DateFormat('MMM dd, yyyy').format(exam.startDate ?? DateTime.now())} - ${DateFormat('MMM dd, yyyy').format(exam.endDate ?? DateTime.now())}',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      if (value == 'view') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ExamViewScreen(exam: exam),
                                          ),
                                        );
                                      } else if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AddEditExamScreen(exam: exam),
                                          ),
                                        );
                                      } else if (value == 'publish') {
                                        _updatePublishStatus(
                                          context,
                                          exam,
                                          true,
                                        );
                                      } else if (value == 'unpublish') {
                                        _updatePublishStatus(
                                          context,
                                          exam,
                                          false,
                                        );
                                      } else if (value == 'duplicate') {
                                        _duplicateExam(context, exam);
                                      } else if (value == 'delete') {
                                        _confirmDelete(context, exam);
                                      }
                                    },
                                    itemBuilder: (context) {
                                      final l10n = AppLocalizations.of(context)!;
                                      return [
                                        PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.visibility_outlined,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(l10n.viewDetails),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.edit_outlined,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(l10n.editExam),
                                            ],
                                          ),
                                        ),
                                        if (!exam.isPublished)
                                          PopupMenuItem(
                                            value: 'publish',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.publish,
                                                  color: Colors.blue,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(l10n.publishResult),
                                              ],
                                            ),
                                          ),
                                        if (exam.isPublished)
                                          PopupMenuItem(
                                            value: 'unpublish',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.unpublished_outlined,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(l10n.unpublishResult),
                                              ],
                                            ),
                                          ),
                                        PopupMenuItem(
                                          value: 'duplicate',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.copy_outlined,
                                                color: Colors.indigo,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(l10n.duplicateExam),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(l10n.deleteExam),
                                            ],
                                          ),
                                        ),
                                      ];
                                    },
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditExamScreen()),
          );
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showExamDetails(BuildContext context, Exam exam) {
    final classes = context.read<ClassSetupNotifier>().classes;
    final subjects = context.read<SubjectSetupNotifier>().subjects;
    final teachers = context.read<TeachersNotifier>().teachers;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          exam.isPublished ? 'Published' : 'Drafting',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (exam.description != null &&
                          exam.description!.isNotEmpty) ...[
                        Text(
                          exam.description!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Schedule',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        Icons.calendar_today_outlined,
                        'Start Date',
                        DateFormat(
                          'EEEE, MMM dd, yyyy',
                        ).format(exam.startDate ?? DateTime.now()),
                      ),
                      _buildDetailItem(
                        Icons.event_available_outlined,
                        'End Date',
                        DateFormat(
                          'EEEE, MMM dd, yyyy',
                        ).format(exam.endDate ?? DateTime.now()),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Assignments (${exam.assignments.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...exam.assignments.map((a) {
                        final className = classes
                            .firstWhere(
                              (c) => c.id == a.classId,
                              orElse: () => ClassRoom(id: '', name: 'N/A'),
                            )
                            .name;
                        final subjectName = subjects
                            .firstWhere(
                              (s) => s.id == a.subjectId,
                              orElse: () => Subject(id: '', name: 'N/A'),
                            )
                            .name;
                        final examinerName =
                            teachers
                                .firstWhere(
                                  (t) => t.userId == a.examinerId,
                                  orElse: () =>
                                      Teacher(userId: '', designation: 'N/A'),
                                )
                                .user
                                ?.name ??
                            'N/A';

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$className • $subjectName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Examiner: $examinerName',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Date: ${DateFormat('MMM dd, yyyy').format(a.date)}',
                                style: TextStyle(
                                  color: Colors.purple.shade300,
                                  fontSize: 12,
                                ),
                              ),
                              if (a.syllabus != null &&
                                  a.syllabus!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Syllabus: ${a.syllabus}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple.shade300),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updatePublishStatus(BuildContext context, Exam exam, bool newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Publish Result' : 'Unpublish Result'),
        content: Text(
          'Are you sure you want to ${newStatus ? 'publish' : 'unpublish'} the results for ${exam.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              List<String> receiverUuids = [];
              if (newStatus) {
                final teacherIds = context
                    .read<TeachersNotifier>()
                    .teachers
                    .map((t) => t.userId)
                    .where((id) => id.isNotEmpty)
                    .toList();
                final studentIds = context
                    .read<StudentsNotifier>()
                    .students
                    .map((s) => s.userId)
                    .where((id) => id.isNotEmpty)
                    .toList();
                receiverUuids = [...teacherIds, ...studentIds];
              }

              await context.read<ExamsNotifier>().updatePublishStatus(
                exam.id,
                newStatus,
                examName: exam.name,
                receiverUuids: receiverUuids,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Results ${newStatus ? 'published' : 'unpublished'} successfully!',
                    ),
                    backgroundColor: newStatus ? Colors.green : Colors.grey,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.purple : Colors.grey.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(newStatus ? 'Publish' : 'Unpublish'),
          ),
        ],
      ),
    );
  }

  void _duplicateExam(BuildContext context, Exam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.duplicateExam),
        content: Text(
          'Are you sure you want to duplicate "${exam.name}"? A new copy will be created.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_outlined, size: 16),
            label: Text(AppLocalizations.of(context)!.duplicateExam),
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<ExamsNotifier>()
                  .duplicateExam(exam.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '"${exam.name}" duplicated successfully!'
                          : 'Failed to duplicate exam. Please try again.',
                    ),
                    backgroundColor:
                        success ? Colors.indigo : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Exam exam) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.deleteExam),
            content: Text(
              'Are you sure you want to delete "${exam.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(90, 38),
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);

                        final success = await context
                            .read<ExamsNotifier>()
                            .deleteExam(exam.id);

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '"${exam.name}" deleted successfully!'
                                    : 'Failed to delete exam. Please try again.',
                              ),
                              backgroundColor:
                                  success ? Colors.red : Colors.orange,
                            ),
                          );
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
        );
      },
    );
  }
}
