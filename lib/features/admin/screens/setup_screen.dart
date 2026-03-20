import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/school_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/setup_provider.dart';
import 'class_detail_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      if (user != null) {
        context.read<ClassSetupNotifier>().fetchClasses(user.schoolId ?? "");
        context.read<SectionSetupNotifier>().fetchSections();
        context.read<SubjectSetupNotifier>().fetchSubjects(user.schoolId ?? "");
      }
    });
  }

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
    final notifier = context.watch<ClassSetupNotifier>();
    final classes = notifier.classes;
    return Scaffold(
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classRoom = classes[index];
                return ListTile(
                  title: Text(classRoom.name),
                  subtitle: classRoom.description.isNotEmpty
                      ? Text(
                          classRoom.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ClassDetailScreen(classRoom: classRoom),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Enter'),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
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
    final notifier = context.watch<SectionSetupNotifier>();
    final sections = notifier.sections;
    final classes = context.watch<ClassSetupNotifier>().classes;
    
    return Scaffold(
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
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
            SizedBox(height: 10),
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
    final notifier = context.watch<SubjectSetupNotifier>();
    final subjects = notifier.subjects;
    final classes = context.watch<ClassSetupNotifier>().classes;

    return Scaffold(
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final className = classes
                    .firstWhere(
                      (c) => c.id == subject.classId,
                      orElse: () => ClassRoom(id: '', name: 'Unknown'),
                    )
                    .name;
                return ListTile(
                  title: Text(
                    '${subject.name} ${subject.code.isNotEmpty ? '(${subject.code})' : ''}',
                  ),
                  subtitle: Text('Class: $className'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSubjectDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addSubjectDialog(BuildContext context) {
    final classes = context.read<ClassSetupNotifier>().classes;
    final user = context.read<AuthNotifier>().user;
    String? selectedClass;
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subject'),
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
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Subject Name (e.g. Mathematics)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Subject Code (e.g. MATH101)',
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
              if (selectedClass != null &&
                  nameController.text.isNotEmpty &&
                  user?.schoolId != null) {
                context.read<SubjectSetupNotifier>().addSubject(
                      nameController.text,
                      codeController.text,
                      selectedClass!,
                      user!.schoolId!,
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
