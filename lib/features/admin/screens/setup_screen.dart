import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/setup_provider.dart';
import '../../../models/school_models.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

class _ClassList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    return Scaffold(
      body: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(classes[index].name),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDialog(context, 'Class', (name) => context.read<ClassSetupNotifier>().addClass(name)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sections = context.watch<SectionSetupNotifier>().sections;
    final classes = context.watch<ClassSetupNotifier>().classes;
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
        onPressed: () => _addSectionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addSectionDialog(BuildContext context) {
    final classes = context.read<ClassSetupNotifier>().classes;
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
                context.read<SectionSetupNotifier>().addSection(selectedClass!, controller.text);
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

class _SubjectList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectSetupNotifier>().subjects;
    return Scaffold(
      body: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) => ListTile(title: Text(subjects[index].name)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDialog(context, 'Subject', (name) => context.read<SubjectSetupNotifier>().addSubject(name)),
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
