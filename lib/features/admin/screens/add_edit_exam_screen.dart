import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/school_models.dart';
import '../providers/exam_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/teacher_provider.dart';
import '../../auth/providers/auth_provider.dart';


class AddEditExamScreen extends StatefulWidget {
  final Exam? exam;
  const AddEditExamScreen({super.key, this.exam});

  @override
  State<AddEditExamScreen> createState() => _AddEditExamScreenState();
}

class _AddEditExamScreenState extends State<AddEditExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedClassId;
  String? _selectedSubjectId;
  String? _selectedExaminerId;

  bool get isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final exam = widget.exam!;
      _nameController.text = exam.name;
      _selectedDate = exam.dateTime;
      _selectedClassId = exam.classId;
      _selectedSubjectId = exam.subjectId;
      _selectedExaminerId = exam.teacherId;
    }
    
    // Fetch dependencies if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeachersNotifier>().fetchTeachers();
      
      final schoolId = context.read<AuthNotifier>().user?.schoolId;
      if (schoolId != null) {
        context.read<ClassSetupNotifier>().fetchClasses(schoolId);
        context.read<SubjectSetupNotifier>().fetchSubjects(schoolId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedClassId == null || _selectedSubjectId == null || _selectedExaminerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Class, Subject, and Examiner'), backgroundColor: Colors.orange),
        );
        return;
      }

      final examsNotifier = context.read<ExamsNotifier>();
      
      try {
        if (isEditing) {
          await examsNotifier.updateExamOnAPI(
            examId: widget.exam!.id,
            examName: _nameController.text.trim(),
            classUid: _selectedClassId!,
            subjectUid: _selectedSubjectId!,
            examinerUid: _selectedExaminerId!,
            date: _selectedDate,
          );
        } else {
          await examsNotifier.createExamOnAPI(
            examName: _nameController.text.trim(),
            classUid: _selectedClassId!,
            subjectUid: _selectedSubjectId!,
            examinerUid: _selectedExaminerId!,
            date: _selectedDate,
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing ? 'Exam updated successfully' : 'Exam created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        log('Error saving exam: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${isEditing ? 'update' : 'create'} exam: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;
    final teachers = context.watch<TeachersNotifier>().teachers;
    final examsNotifier = context.watch<ExamsNotifier>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Exam' : 'Create Exam'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Exam basic details
            _buildSectionHeader(context, 'Exam Details', Icons.assignment_outlined),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Exam Name',
                        hintText: 'e.g. Final Exam 2024',
                        prefixIcon: const Icon(Icons.edit_note),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? 'Please enter exam name' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.purple,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Exam Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Academic details
            _buildSectionHeader(context, 'Academic Assignment', Icons.school_outlined),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Class',
                        prefixIcon: const Icon(Icons.class_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      value: _selectedClassId,
                      items: classes
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val;
                          _selectedSubjectId = null; // Reset subject when class changes
                        });
                      },
                      validator: (val) => val == null ? 'Please select class' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: const Icon(Icons.book_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      value: _selectedSubjectId,
                      items: subjects
                          .where((s) => s.classId == _selectedClassId)
                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedSubjectId = val),
                      validator: (val) => val == null ? 'Please select subject' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Examiner',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      value: _selectedExaminerId,
                      items: teachers
                          .map((t) => DropdownMenuItem(
                                value: t.userId,
                                child: Text(t.user?.name ?? 'Unknown Teacher'),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedExaminerId = val),
                      validator: (val) => val == null ? 'Please select examiner' : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: examsNotifier.isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: examsNotifier.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'Update Exam' : 'Create Exam',
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
}
