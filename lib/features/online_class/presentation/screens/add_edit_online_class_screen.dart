import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/data/mock_data/mock_data.dart';
import 'package:smart_school/models/online_class_model.dart';
import 'package:smart_school/features/online_class/providers/online_class_provider.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/models/school_models.dart';

class AddEditOnlineClassScreen extends StatefulWidget {
  final OnlineClass? onlineClass;
  final bool isAdminOrTeacher;
  const AddEditOnlineClassScreen({
    super.key,
    this.onlineClass,
    this.isAdminOrTeacher = true,
  });

  @override
  State<AddEditOnlineClassScreen> createState() =>
      _AddEditOnlineClassScreenState();
}

class _AddEditOnlineClassScreenState extends State<AddEditOnlineClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedEndTime;

  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.onlineClass != null) {
      _titleController.text = widget.onlineClass!.title;
      _descController.text = widget.onlineClass!.description;
      _linkController.text = widget.onlineClass!.meetLink;
      _selectedDate = widget.onlineClass!.scheduledTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.onlineClass!.scheduledTime);
      _selectedEndTime = TimeOfDay.fromDateTime(widget.onlineClass!.scheduledTime.add(const Duration(hours: 1)));
      _selectedClassId = widget.onlineClass!.classId;
      _selectedSectionId = widget.onlineClass!.sectionId;
      _selectedSubjectId = widget.onlineClass!.subjectId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedEndTime = time);
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null || _selectedEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date, start time, and end time')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final isEditing = widget.onlineClass != null;

      if (!isEditing) {
        final dateStr = _selectedDate!.toUtc().toIso8601String();
        
        final startTimeStr = _selectedTime!.format(context);
        final endTimeStr = _selectedEndTime!.format(context);

        final success = await context.read<OnlineClassProvider>().createOnlineClass(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          meetLink: _linkController.text.trim(),
          date: dateStr,
          startTime: startTimeStr,
          endTime: endTimeStr,
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
          subjectId: _selectedSubjectId,
        );

        setState(() => _isLoading = false);

        if (success && mounted) {
          Navigator.pop(context, true);
        } else if (mounted) {
          final error = context.read<OnlineClassProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Failed to create online class')),
          );
        }
      } else {
        // Mock update for now
        final scheduledDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        final newClass = OnlineClass(
          id: widget.onlineClass!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          meetLink: _linkController.text.trim(),
          scheduledTime: scheduledDateTime,
          teacherId: 't1',
          teacherName: 'Masihur Rahman',
        );

        final index = MockData.onlineClasses.indexWhere(
          (c) => c['id'] == widget.onlineClass!.id,
        );
        if (index != -1) {
          MockData.onlineClasses[index] = newClass.toJson();
        }

        setState(() => _isLoading = false);
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.onlineClass == null
              ? 'Create Online Class'
              : 'Edit Online Class',
        ),
        backgroundColor: widget.isAdminOrTeacher
            ? AppColors.primaryAdmin
            : AppColors.primaryTeacher,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Class Details'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'e.g., Mathematics Chapter 1',
                icon: Icons.title,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Optional description for the class',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Academic Details'),
              const SizedBox(height: 12),
              _buildDropdowns(),
              const SizedBox(height: 24),
              _buildSectionTitle('Meeting Details'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _linkController,
                label: 'Google Meet Link',
                hint: 'https://meet.google.com/xxx-xxxx-xxx',
                icon: Icons.link,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Link is required';
                  if (!val.startsWith('http://') &&
                      !val.startsWith('https://')) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'Date',
                      value: _selectedDate != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                          : 'Select Date',
                      icon: Icons.calendar_today,
                      onTap: _pickDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'Start Time',
                      value: _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Select Time',
                      icon: Icons.access_time,
                      onTap: _pickTime,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'End Time',
                      value: _selectedEndTime != null
                          ? _selectedEndTime!.format(context)
                          : 'Select Time',
                      icon: Icons.access_time,
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isAdminOrTeacher
                        ? AppColors.primaryAdmin
                        : AppColors.primaryTeacher,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Class',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: maxLines == 1
            ? Icon(icon, color: AppColors.textSecondary)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdowns() {
    final classSetup = context.watch<ClassSetupNotifier>();
    final sectionSetup = context.watch<SectionSetupNotifier>();
    final subjectSetup = context.watch<SubjectSetupNotifier>();

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedClassId,
          decoration: _buildInputDecoration('Class', Icons.class_),
          items: classSetup.classes.map((c) {
            return DropdownMenuItem(value: c.id, child: Text(c.name));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedClassId = val;
              _selectedSectionId = null;
              _selectedSubjectId = null;
            });
          },
          validator: (val) => val == null ? 'Please select a class' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedSectionId,
          decoration: _buildInputDecoration('Section', Icons.group),
          items: sectionSetup.sections
              .where((s) => s.classId == _selectedClassId)
              .map((s) {
            return DropdownMenuItem(value: s.id, child: Text(s.name));
          }).toList(),
          onChanged: (val) => setState(() => _selectedSectionId = val),
          validator: (val) => val == null ? 'Please select a section' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedSubjectId,
          decoration: _buildInputDecoration('Subject', Icons.book),
          items: subjectSetup.subjects
              .where((s) => s.classId == _selectedClassId)
              .map((s) {
            return DropdownMenuItem(value: s.id, child: Text(s.name));
          }).toList(),
          onChanged: (val) => setState(() => _selectedSubjectId = val),
          validator: (val) => val == null ? 'Please select a subject' : null,
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
