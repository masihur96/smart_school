import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routine_provider.dart';
import '../providers/student_provider.dart';
import '../providers/teacher_provider.dart';
import '../../../models/school_models.dart';

class RoutineManagementScreen extends ConsumerStatefulWidget {
  const RoutineManagementScreen({super.key});

  @override
  ConsumerState<RoutineManagementScreen> createState() => _RoutineManagementScreenState();
}

class _RoutineManagementScreenState extends ConsumerState<RoutineManagementScreen> {
  String? _selectedClass;
  String? _selectedSection;

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider);
    final sections = ref.watch(sectionsProvider);
    final routineEntries = (_selectedClass != null && _selectedSection != null)
        ? ref.watch(routineProvider)['${_selectedClass}_$_selectedSection'] ?? []
        : <RoutineEntry>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routine'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Class'),
                    value: _selectedClass,
                    items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() { _selectedClass = val; _selectedSection = null; }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Section'),
                    value: _selectedSection,
                    items: sections.where((s) => s.classId == _selectedClass).map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (val) => setState(() => _selectedSection = val),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: (_selectedClass == null || _selectedSection == null)
                ? const Center(child: Text('Select Class and Section to see routine'))
                : ListView.builder(
                    itemCount: routineEntries.length,
                    itemBuilder: (context, index) {
                      final entry = routineEntries[index];
                      final subjectName = ref.read(subjectsProvider).firstWhere((s) => s.id == entry.subjectId).name;
                      final teacherName = ref.read(teachersProvider).firstWhere((t) => t.userId == entry.teacherId).user?.name ?? 'Unknown';
                      return ListTile(
                        leading: CircleAvatar(child: Text(entry.day[0])),
                        title: Text('$subjectName (${entry.day})'),
                        subtitle: Text('$teacherName | ${entry.startTime} - ${entry.endTime}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => ref.read(routineProvider.notifier).removeEntry(_selectedClass!, _selectedSection!, index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: (_selectedClass != null && _selectedSection != null)
          ? FloatingActionButton(
              onPressed: () => _addEntryDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _addEntryDialog(BuildContext context, WidgetRef ref) {
    final subjects = ref.read(subjectsProvider);
    final teachers = ref.read(teachersProvider);
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    String? day = days[0];
    String? subjectId;
    String? teacherId;
    final startController = TextEditingController(text: '09:00 AM');
    final endController = TextEditingController(text: '10:00 AM');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Routine Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: day,
                decoration: const InputDecoration(labelText: 'Day'),
                items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => day = val,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Subject'),
                items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (val) => subjectId = val,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Teacher'),
                items: teachers.map((t) => DropdownMenuItem(value: t.userId, child: Text(t.user?.name ?? 'Unknown'))).toList(),
                onChanged: (val) => teacherId = val,
              ),
              TextField(controller: startController, decoration: const InputDecoration(labelText: 'Start Time (e.g. 09:00 AM)')),
              TextField(controller: endController, decoration: const InputDecoration(labelText: 'End Time (e.g. 10:00 AM)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (day != null && subjectId != null && teacherId != null) {
                ref.read(routineProvider.notifier).addEntry(
                      _selectedClass!,
                      _selectedSection!,
                      RoutineEntry(
                        day: day!,
                        startTime: startController.text,
                        endTime: endController.text,
                        subjectId: subjectId!,
                        teacherId: teacherId!,
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
