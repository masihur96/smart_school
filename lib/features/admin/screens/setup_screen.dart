import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/setup_provider.dart';
import '../../../models/school_models.dart';

class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Class & Subject Setup'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Classes'),
              Tab(text: 'Sections'),
              Tab(text: 'Subjects'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _ClassList(),
            _SectionList(),
            _SubjectList(),
          ],
        ),
      ),
    );
  }
}

class _ClassList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classSetupProvider);
    return Scaffold(
      body: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(classes[index].name),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDialog(context, 'Class', (name) => ref.read(classSetupProvider.notifier).addClass(name)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SectionList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(sectionSetupProvider);
    final classes = ref.watch(classSetupProvider);
    return Scaffold(
      body: ListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          final className = classes.firstWhere((c) => c.id == section.classId, orElse: () => ClassRoom(id: '', name: 'Unknown')).name;
          return ListTile(
            title: Text('Section ${section.name}'),
            subtitle: Text('Class: $className'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSectionDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addSectionDialog(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classSetupProvider);
    String? selectedClass;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Section'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Class'),
              items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (val) => selectedClass = val,
            ),
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Section Name (e.g. A)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (selectedClass != null && controller.text.isNotEmpty) {
                ref.read(sectionSetupProvider.notifier).addSection(selectedClass!, controller.text);
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

class _SubjectList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectSetupProvider);
    return Scaffold(
      body: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) => ListTile(title: Text(subjects[index].name)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDialog(context, 'Subject', (name) => ref.read(subjectSetupProvider.notifier).addSubject(name)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

void _addDialog(BuildContext context, String type, Function(String) onAdd) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add $type'),
      content: TextField(controller: controller, decoration: InputDecoration(labelText: '$type Name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              onAdd(controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
