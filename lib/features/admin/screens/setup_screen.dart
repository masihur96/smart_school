import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/setup_provider.dart';
import '../../../models/school_models.dart';
import '../../auth/providers/auth_provider.dart';

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
          children: [_ClassList(), _SectionList(), _SubjectList()],
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
        onPressed: () {
          final user = context.read<AuthNotifier>().user;
          _addDialog(
            context,
            'Class',
            (name, desc) => context.read<ClassSetupNotifier>().addClass(
              name,
              desc,
              user?.schoolId ?? '',
            ),
          );
        },
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
          final className = classes
              .firstWhere(
                (c) => c.id == section.classId,
                orElse: () => ClassRoom(id: '', name: 'Unknown'),
              )
              .name;
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
              items: classes
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (val) => selectedClass = val,
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Section Name (e.g. A)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedClass != null && controller.text.isNotEmpty) {
                context.read<SectionSetupNotifier>().addSection(
                  selectedClass!,
                  controller.text,
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

class _SubjectList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectSetupNotifier>().subjects;
    return Scaffold(
      body: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) =>
            ListTile(title: Text(subjects[index].name)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDialog(
          context,
          'Subject',
          (name, desc) => context.read<SubjectSetupNotifier>().addSubject(name),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

void _addDialog(
  BuildContext context,
  String type,
  Function(String name, String description) onAdd,
) {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add $type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: '$type Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              onAdd(nameController.text, descController.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
