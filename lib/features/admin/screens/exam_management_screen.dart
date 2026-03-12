import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/school_models.dart';
import '../providers/exam_provider.dart';
import '../providers/setup_provider.dart';
import '../../../services/database_service.dart';

class ExamManagementScreen extends StatefulWidget {
  final bool hideAppBar;
  const ExamManagementScreen({super.key, this.hideAppBar = false});

  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final exams = context.watch<ExamsNotifier>().state;
    final classes = context.watch<ClassSetupNotifier>().classes;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Exam Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: exams.isEmpty
          ? const Center(child: Text('No exams scheduled.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                final className = classes.firstWhere((c) => c.id == exam.classId).name;
                final subjectName = subjects.firstWhere((s) => s.id == exam.subjectId).name;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(exam.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$className - $subjectName'),
                        Text(DateFormat('MMM dd, yyyy - hh:mm a').format(exam.dateTime)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!exam.isPublished)
                          IconButton(
                            icon: const Icon(Icons.publish, color: Colors.blue),
                            onPressed: () => _publishResult(exam),
                            tooltip: 'Publish Result',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => context.read<ExamsNotifier>().deleteExam(exam.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExamDialog(context),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _publishResult(Exam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Result'),
        content: Text('Are you sure you want to publish the results for ${exam.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<ExamsNotifier>().publishResult(exam.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Results published successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _showAddExamDialog(BuildContext context) {
    final nameController = TextEditingController();
    String? selectedClassId;
    String? selectedSubjectId;
    String? selectedTeacherId; // For simplicity, we'll just pick a teacher later or from a list
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final classes = context.watch<ClassSetupNotifier>().classes;
            final subjects = context.watch<SubjectSetupNotifier>().subjects;
            // We need a list of teachers, let's assume we can get it from databaseServiceProvider or similar
            final db = context.read<DatabaseService>();
            final teachersList = db.teachers;

            return AlertDialog(
              title: const Text('Add New Exam'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Exam Name'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedClassId,
                      decoration: const InputDecoration(labelText: 'Class'),
                      items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) => setState(() => selectedClassId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) => setState(() => selectedSubjectId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedTeacherId,
                      decoration: const InputDecoration(labelText: 'Examiner'),
                      items: teachersList.map((t) => DropdownMenuItem(value: t.userId, child: Text(t.user?.name ?? 'Unknown Teacher'))).toList(),
                      onChanged: (val) => setState(() => selectedTeacherId = val),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        selectedClassId != null &&
                        selectedSubjectId != null &&
                        selectedTeacherId != null) {
                      final exam = Exam(
                        id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text,
                        subjectId: selectedSubjectId!,
                        teacherId: selectedTeacherId!,
                        classId: selectedClassId!,
                        sectionId: 's1', // Default section for now
                        dateTime: selectedDate,
                      );
                      context.read<ExamsNotifier>().addExam(exam);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
