import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/student_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';

class AddEditStudentScreen extends StatefulWidget {
  final Student? student;
  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aboutController = TextEditingController();
  String? _selectedClass;
  String? _selectedSection;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      final s = widget.student!;
      _nameController.text = s.user?.name ?? '';
      _emailController.text = s.user?.email ?? '';
      _rollController.text = s.rollId;
      _phoneController.text = s.user?.phone ?? s.guardianContact;
      _selectedClass = s.classId.isEmpty ? null : s.classId;
      _selectedSection = s.sectionId.isEmpty ? null : s.sectionId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rollController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final user = context.read<AuthNotifier>().user;
      final schoolId = user?.schoolId ?? '';

      try {
        if (widget.student != null) {
          await context.read<StudentsNotifier>().updateStudentToAPI(
            userId: widget.student!.userId,
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            phone: _phoneController.text,
            classId: _selectedClass!,
            sectionId: _selectedSection!,
            rollNumber: _rollController.text,
            designation: _aboutController.text,
          );
        } else {
          await context.read<StudentsNotifier>().addStudentToAPI(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            role: 'student',
            schoolId: schoolId,
            phone: _phoneController.text,
            classId: _selectedClass!,
            sectionId: _selectedSection!,
            rollNumber: _rollController.text,
            designation: _aboutController.text,
          );
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student != null ? 'Edit Student' : 'Add Student'),
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
              controller: _aboutController,
              decoration: const InputDecoration(
                labelText: 'About (e.g. About Student)',
                prefixIcon: Icon(Icons.badge),
              ),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: widget.student != null
                    ? 'Password (leave blank to keep current)'
                    : 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (val) {
                if (widget.student == null && (val == null || val.isEmpty)) {
                  return 'Please enter password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rollController,
                    decoration: const InputDecoration(
                      labelText: 'Roll Number',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Class',
                prefixIcon: Icon(Icons.class_),
              ),
              value: classes.any((c) => c.id == _selectedClass)
                  ? _selectedClass
                  : null,
              items: classes
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedClass = val;
                  _selectedSection = null;
                });
              },
              validator: (val) => val == null ? 'Please select class' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Section',
                prefixIcon: Icon(Icons.grid_view),
              ),
              value:
                  sections.any(
                    (s) =>
                        s.id == _selectedSection && s.classId == _selectedClass,
                  )
                  ? _selectedSection
                  : null,
              items: sections
                  .where((s) => s.classId == _selectedClass)
                  .map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedSection = val),
              validator: (val) => val == null ? 'Please select section' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: Text(
                widget.student != null ? 'Update Student' : 'Save Student',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
