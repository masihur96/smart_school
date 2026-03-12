import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/student_provider.dart';
import '../providers/setup_provider.dart';
import '../../../models/student_model.dart';
import '../../../models/user_model.dart';

class AddEditStudentScreen extends StatefulWidget {
  const AddEditStudentScreen({super.key});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _rollController = TextEditingController();
  final _guardianController = TextEditingController();
  String? _selectedClass;
  String? _selectedSection;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollController.dispose();
    _guardianController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newStudent = Student(
        userId: DateTime.now().millisecondsSinceEpoch.toString(),
        rollId: _rollController.text,
        classId: _selectedClass!,
        sectionId: _selectedSection!,
        guardianContact: _guardianController.text,
        user: User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          email: _emailController.text,
          role: UserRole.student,
        ),
      );

      context.read<StudentsNotifier>().addStudent(newStudent);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
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
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
              validator: (val) => val!.isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
              validator: (val) => val!.isEmpty ? 'Please enter email' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rollController,
                    decoration: const InputDecoration(labelText: 'Roll / ID', prefixIcon: Icon(Icons.numbers)),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _guardianController,
                    decoration: const InputDecoration(labelText: 'Guardian Contact', prefixIcon: Icon(Icons.phone)),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.class_)),
              value: _selectedClass,
              items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (val) => setState(() => _selectedClass = val),
              validator: (val) => val == null ? 'Please select class' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Section', prefixIcon: Icon(Icons.grid_view)),
              value: _selectedSection,
              items: sections.where((s) => s.classId == _selectedClass).map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (val) => setState(() => _selectedSection = val),
              validator: (val) => val == null ? 'Please select section' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Save Student', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
