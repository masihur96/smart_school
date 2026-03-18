import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
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
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  String? _selectedClassId;
  String? _selectedSectionId;
  final List<AssignedSubject> _assignedSubjects = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedClassId == null || _selectedSectionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Class and Section')),
        );
        return;
      }

      final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
      
      try {
        await context.read<TeachersNotifier>().addTeacherToAPI(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          schoolId: schoolId,
          phone: _phoneController.text,
          classId: _selectedClassId!,
          sectionId: _selectedSectionId!,
          designation: _designationController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher registered successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $e')),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;
    final teacherNotifier = context.watch<TeachersNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Teacher'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [

            
            // Personal Details Section
            _buildSectionHeader(context, 'Personal Details', Icons.person_outline),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val!.isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val!.isEmpty ? 'Please enter email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val!.isEmpty ? 'Please enter phone' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Account Security Section
            _buildSectionHeader(context, 'Account Security', Icons.lock_outline),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.security),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val!.length < 6 ? 'Password too short' : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Professional Details Section
            _buildSectionHeader(context, 'Professional Details', Icons.work_outline),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _designationController,
                      decoration: InputDecoration(
                        labelText: 'Designation',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val!.isEmpty ? 'Please enter designation' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Assigned Class',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.class_outlined),
                      ),
                      items: classes
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      value: _selectedClassId,
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val;
                          _selectedSectionId = null;
                        });
                      },
                      validator: (val) => val == null ? 'Please select class' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Assigned Section',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.groups_outlined),
                      ),
                      items: sections
                          .where((s) => s.classId == _selectedClassId)
                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                          .toList(),
                      value: _selectedSectionId,
                      onChanged: (val) => setState(() => _selectedSectionId = val),
                      validator: (val) => val == null ? 'Please select section' : null,
                    ),
                  ],
                ),
              ),
            ),


            const SizedBox(height: 32),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: teacherNotifier.isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: teacherNotifier.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Register Teacher',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }


}
