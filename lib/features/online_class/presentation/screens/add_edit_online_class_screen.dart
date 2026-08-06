import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/data/mock_data/mock_data.dart';
import 'package:smart_school/models/online_class_model.dart';

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

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both date and time')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final isEditing = widget.onlineClass != null;
      final newClass = OnlineClass(
        id: isEditing
            ? widget.onlineClass!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        meetLink: _linkController.text.trim(),
        scheduledTime: scheduledDateTime,
        teacherId: 't1', // Assuming current user is a teacher
        teacherName: 'Masihur Rahman', // Dummy data for now
      );

      if (isEditing) {
        final index = MockData.onlineClasses.indexWhere(
          (c) => c['id'] == widget.onlineClass!.id,
        );
        if (index != -1) {
          MockData.onlineClasses[index] = newClass.toJson();
        }
      } else {
        MockData.onlineClasses.add(newClass.toJson());
      }

      setState(() => _isLoading = false);
      Navigator.pop(context, true);
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'Time',
                      value: _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Select Time',
                      icon: Icons.access_time,
                      onTap: _pickTime,
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
}
