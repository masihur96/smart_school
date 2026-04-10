import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';

import '../../../models/teacher_model.dart';
import '../providers/setup_provider.dart';
import '../providers/teacher_provider.dart';

class AddEditTeacherScreen extends StatefulWidget {
  final Teacher? teacher;
  const AddEditTeacherScreen({super.key, this.teacher});

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
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _radiusController = TextEditingController();
  String? _selectedClassId;
  String? _selectedSectionId;
  final List<AssignedSubject> _assignedSubjects = [];
  bool _obscurePassword = true;

  bool get isEditing => widget.teacher != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final teacher = widget.teacher!;
      _nameController.text = teacher.user?.name ?? '';
      _emailController.text = teacher.user?.email ?? '';
      _phoneController.text = teacher.user?.phone ?? '';
      _designationController.text = teacher.designation;
      _selectedClassId = teacher.classId;
      _selectedSectionId = teacher.sectionId;
      _latController.text = teacher.lat?.toString() ?? '';
      _lonController.text = teacher.lon?.toString() ?? '';
      _radiusController.text = teacher.radius?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _radiusController.dispose();
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
      final teacherNotifier = context.read<TeachersNotifier>();

      try {
        if (isEditing) {
          await teacherNotifier.updateTeacherOnAPI(
            userId: widget.teacher!.userId,
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            classId: _selectedClassId!,
            sectionId: _selectedSectionId!,
            designation: _designationController.text,
            lat: double.tryParse(_latController.text),
            lon: double.tryParse(_lonController.text),
            radius: double.tryParse(_radiusController.text),
          );
        } else {
          await teacherNotifier.addTeacherToAPI(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            schoolId: schoolId,
            phone: _phoneController.text,
            classId: _selectedClassId!,
            sectionId: _selectedSectionId!,
            designation: _designationController.text,
            lat: double.tryParse(_latController.text),
            lon: double.tryParse(_lonController.text),
            radius: double.tryParse(_radiusController.text),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Teacher updated successfully'
                    : 'Teacher registered successfully',
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${isEditing ? 'Update' : 'Registration'} failed: $e',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;
    final teacherNotifier = context.watch<TeachersNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Teacher' : 'Register Teacher'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Personal Details Section
            _buildSectionHeader(
              context,
              'Personal Details',
              Icons.person_outline,
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter phone' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Account Security Section
            if (!isEditing) ...[
              _buildSectionHeader(
                context,
                'Account Security',
                Icons.lock_outline,
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.security),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) =>
                        val!.length < 6 ? 'Password too short' : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Professional Details Section
            _buildSectionHeader(
              context,
              'Professional Details',
              Icons.work_outline,
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _designationController,
                      decoration: InputDecoration(
                        labelText: 'Designation',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter designation' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Assigned Class',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.class_outlined),
                      ),
                      items: classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      value: classes.any((c) => c.id == _selectedClassId)
                          ? _selectedClassId
                          : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val;
                          _selectedSectionId = null;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Please select class' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Assigned Section',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.groups_outlined),
                      ),
                      items: sections
                          .where((s) => s.classId == _selectedClassId)
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      value:
                          sections.any(
                            (s) =>
                                s.id == _selectedSectionId &&
                                s.classId == _selectedClassId,
                          )
                          ? _selectedSectionId
                          : null,
                      onChanged: (val) =>
                          setState(() => _selectedSectionId = val),
                      validator: (val) =>
                          val == null ? 'Please select section' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location Settings Section
            _buildSectionHeader(
              context,
              'Arrival Settings',
              Icons.location_on_outlined,
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Latitude',
                              prefixIcon: const Icon(Icons.map_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lonController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Longitude',
                              prefixIcon: const Icon(Icons.explore_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Allowed Radius (meters)',
                        prefixIcon: const Icon(Icons.radar_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Radius in meters for arrival check',
                      ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: teacherNotifier.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing ? 'Update Teacher' : 'Register Teacher',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
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
}
