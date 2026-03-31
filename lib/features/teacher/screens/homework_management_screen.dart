import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/homework_provider.dart';
import '../../admin/providers/student_provider.dart';
import '../../admin/providers/setup_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/school_models.dart';
import 'package:intl/intl.dart';

class HomeworkManagementScreen extends StatefulWidget {
  final bool hideAppBar;
  const HomeworkManagementScreen({super.key, this.hideAppBar = false});

  @override
  State<HomeworkManagementScreen> createState() => _HomeworkManagementScreenState();
}

class _HomeworkManagementScreenState extends State<HomeworkManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
    if (schoolId.isNotEmpty) {
      await context.read<ClassSetupNotifier>().fetchClasses(schoolId);
      await context.read<SectionSetupNotifier>().fetchSections();
      await context.read<SubjectSetupNotifier>().fetchSubjects(schoolId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthNotifier>().user;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    final homeworkNotifier = context.watch<HomeworkNotifier>();
    final homeworkList = homeworkNotifier.getHomeworkForTeacher(currentUser.id);
    final classes = context.watch<ClassSetupNotifier>().classes;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('My Homeworks'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
      body: homeworkList.isEmpty
          ? const Center(child: Text('No homeworks posted yet.'))
          : ListView.builder(
              itemCount: homeworkList.length,
              itemBuilder: (context, index) {
                final hw = homeworkList[index];
                final className = classes
                    .firstWhere(
                      (c) => c.id == hw.classId,
                      orElse: () => ClassRoom(id: '', name: 'Unknown'),
                    )
                    .name;
                final subName = subjects
                    .firstWhere(
                      (s) => s.id == hw.subjectId,
                      orElse: () => Subject(id: '', name: 'Unknown'),
                    )
                    .name;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      hw.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$className - $subName'),
                        Text(
                          'Due: ${DateFormat('MMM d, yyyy').format(hw.dueDate)}',
                          style: TextStyle(
                            color: hw.dueDate.isBefore(DateTime.now())
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'view') {
                          _viewHomeworkDialog(context, hw);
                        } else if (value == 'edit') {
                          _updateHomeworkDialog(context, hw);
                        } else if (value == 'delete') {
                          _confirmDelete(context, hw.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: ListTile(
                            leading: Icon(Icons.visibility),
                            title: Text('View'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title:
                                Text('Delete', style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addHomeworkDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _viewHomeworkDialog(BuildContext context, Homework hw) {
    final classes = context.read<ClassSetupNotifier>().classes;
    final subjects = context.read<SubjectSetupNotifier>().subjects;
    final className = classes
        .firstWhere((c) => c.id == hw.classId,
            orElse: () => ClassRoom(id: '', name: 'Unknown'))
        .name;
    final subName = subjects
        .firstWhere((s) => s.id == hw.subjectId,
            orElse: () => Subject(id: '', name: 'Unknown'))
        .name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hw.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class: $className'),
            Text('Subject: $subName'),
            const SizedBox(height: 10),
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(hw.description.isNotEmpty ? hw.description : 'No description'),
            const SizedBox(height: 10),
            Text('Due Date: ${DateFormat('yyyy-MM-dd').format(hw.dueDate)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateHomeworkDialog(BuildContext context, Homework hw) {
    final titleController = TextEditingController(text: hw.title);
    final descController = TextEditingController(text: hw.description);
    String? selectedClass = hw.classId;
    String? selectedSection = hw.sectionId;
    String? selectedSubject = hw.subjectId;
    DateTime selectedDate = hw.dueDate;

    final classes = context.read<ClassSetupNotifier>().classes;
    final sections = context.read<SectionSetupNotifier>().sections;
    final subjects = context.read<SubjectSetupNotifier>().subjects;
    final currentUser = context.read<AuthNotifier>().user!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Homework'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Class'),
                  value: selectedClass,
                  items: classes
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (val) => setState(() {
                    selectedClass = val;
                    selectedSection = null;
                    selectedSubject = null;
                  }),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Section'),
                  value: selectedSection,
                  items: sections
                      .where((s) => s.classId == selectedClass)
                      .map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedSection = val),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Subject'),
                  value: selectedSubject,
                  items: subjects
                      .where((s) => s.classId == selectedClass)
                      .map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedSubject = val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Due Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                      ),
                    ),
                    TextButton(
                      child: const Text('Pick Date'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    selectedClass != null &&
                    selectedSubject != null) {
                  final success = await context.read<HomeworkNotifier>().updateHomework(
                        Homework(
                          id: hw.id,
                          title: titleController.text,
                          description: descController.text,
                          classId: selectedClass!,
                          sectionId: selectedSection ?? '',
                          subjectId: selectedSubject!,
                          teacherId: currentUser.id,
                          schoolId: currentUser.schoolId ?? '',
                          dueDate: selectedDate,
                          createdAt: hw.createdAt,
                        ),
                      );
                  if (context.mounted) {
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update homework')),
                      );
                    }
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Homework'),
        content: const Text('Are you sure you want to delete this homework?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<HomeworkNotifier>().removeHomework(id);
              if (context.mounted) {
                Navigator.pop(context);
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

  void _addHomeworkDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedClass;
    String? selectedSection;
    String? selectedSubject;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    final classes = context.read<ClassSetupNotifier>().classes;
    final sections = context.read<SectionSetupNotifier>().sections;
    final subjects = context.read<SubjectSetupNotifier>().subjects;
    final currentUser = context.read<AuthNotifier>().user!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Post Homework'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Class'),
                  value: selectedClass,
                  items: classes
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() {
                    selectedClass = val;
                    selectedSection = null;
                    selectedSubject = null; // Reset subject when class changes
                  }),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Section'),
                  value: selectedSection,
                  items: sections
                      .where((s) => s.classId == selectedClass)
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedSection = val),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Subject'),
                  value: selectedSubject,
                  items: subjects
                      .where((s) => s.classId == selectedClass)
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedSubject = val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Due Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                      ),
                    ),
                    TextButton(
                      child: const Text('Pick Date'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null)
                          setState(() => selectedDate = picked);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    selectedClass != null &&
                    selectedSubject != null) {
                  final success =
                      await context.read<HomeworkNotifier>().submitHomework(
                            Homework(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              title: titleController.text,
                              description: descController.text,
                              classId: selectedClass!,
                              sectionId: selectedSection!,
                              subjectId: selectedSubject!,
                              teacherId: currentUser.id,
                              schoolId: currentUser.schoolId ?? '',
                              dueDate: selectedDate,
                              createdAt: DateTime.now(),
                            ),
                          );
                  if (context.mounted) {
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to submit homework')),
                      );
                    }
                  }
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
