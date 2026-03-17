import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/teacher_provider.dart';
import '../providers/setup_provider.dart';
import '../../../models/teacher_model.dart';
import '../../../models/user_model.dart';

class AddEditTeacherScreen extends StatefulWidget {
  const AddEditTeacherScreen({super.key});

  @override
  State<AddEditTeacherScreen> createState() => _AddEditTeacherScreenState();
}

class _AddEditTeacherScreenState extends State<AddEditTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final List<AssignedSubject> _assignedSubjects = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newTeacher = Teacher(
        userId: DateTime.now().millisecondsSinceEpoch.toString(),
        assignedSubjects: _assignedSubjects,
        user: User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          email: _emailController.text,
          role: UserRole.teacher,
        ),
      );

      context.read<TeachersNotifier>().addTeacher(newTeacher);
      context.pop();
    }
  }

  void _addSubject() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedClass;
        String? selectedSection;
        String? selectedSub;
        final classes = context.watch<ClassSetupNotifier>().classes;
        final sections = context.watch<SectionSetupNotifier>().sections;
        final subjects = context.watch<SubjectSetupNotifier>().subjects;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Subject'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: classes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedClass = val),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: sections
                        .where((s) => s.classId == selectedClass)
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedSection = val),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: subjects
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setDialogState(() => selectedSub = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      (selectedClass != null &&
                          selectedSection != null &&
                          selectedSub != null)
                      ? () {
                          setState(() {
                            _assignedSubjects.add(
                              AssignedSubject(
                                classId: selectedClass!,
                                sectionId: selectedSection!,
                                subjectId: selectedSub!,
                              ),
                            );
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Teacher'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (val) => val!.isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (val) => val!.isEmpty ? 'Please enter email' : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Subjects',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSubject,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const Divider(),
            if (_assignedSubjects.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No subjects assigned yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ..._assignedSubjects.asMap().entries.map((entry) {
              final idx = entry.key;
              final sub = entry.value;
              final className = classes
                  .firstWhere((c) => c.id == sub.classId)
                  .name;
              final subName = subjects
                  .firstWhere((s) => s.id == sub.subjectId)
                  .name;
              return ListTile(
                title: Text('$className - $subName'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () =>
                      setState(() => _assignedSubjects.removeAt(idx)),
                ),
              );
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text(
                'Save Teacher',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
