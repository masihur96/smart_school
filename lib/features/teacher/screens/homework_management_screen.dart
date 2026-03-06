import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/homework_provider.dart';
import '../../admin/providers/student_provider.dart';
import '../../admin/providers/teacher_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/school_models.dart';
import 'package:intl/intl.dart';

class HomeworkManagementScreen extends ConsumerWidget {
  const HomeworkManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('Please login')));

    final homeworkList = ref.watch(homeworkProvider).where((h) => h.teacherId == currentUser.id).toList();
    final classes = ref.watch(classesProvider);
    final subjects = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
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
                final className = classes.firstWhere((c) => c.id == hw.classId, orElse: () => ClassRoom(id: '', name: 'Unknown')).name;
                final subName = subjects.firstWhere((s) => s.id == hw.subjectId, orElse: () => Subject(id: '', name: 'Unknown')).name;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(hw.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$className - $subName'),
                        Text('Due: ${DateFormat('MMM d, yyyy').format(hw.dueDate)}', 
                             style: TextStyle(color: hw.dueDate.isBefore(DateTime.now()) ? Colors.red : Colors.green)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () => ref.read(homeworkProvider.notifier).removeHomework(hw.id),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addHomeworkDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addHomeworkDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedClass;
    String? selectedSection;
    String? selectedSubject;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    
    final classes = ref.read(classesProvider);
    final sections = ref.read(sectionsProvider);
    final subjects = ref.read(subjectsProvider);
    final currentUser = ref.read(authProvider).user!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Post Homework'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Class'),
                  value: selectedClass,
                  items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() { selectedClass = val; selectedSection = null; }),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Section'),
                  value: selectedSection,
                  items: sections.where((s) => s.classId == selectedClass).map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) => setState(() => selectedSection = val),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Subject'),
                  value: selectedSubject,
                  items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) => setState(() => selectedSubject = val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Text('Due Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}')),
                    TextButton(
                      child: const Text('Pick Date'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && selectedClass != null && selectedSubject != null) {
                  ref.read(homeworkProvider.notifier).addHomework(Homework(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descController.text,
                    classId: selectedClass!,
                    sectionId: selectedSection!,
                    subjectId: selectedSubject!,
                    teacherId: currentUser.id,
                    dueDate: selectedDate, createdAt:  DateTime.now(),
                  ));
                  Navigator.pop(context);
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
