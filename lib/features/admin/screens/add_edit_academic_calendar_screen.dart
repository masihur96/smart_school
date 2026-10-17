import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/models/academic_calendar_model.dart';
import 'package:smart_school/features/admin/providers/academic_calendar_provider.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';

class AddEditAcademicCalendarScreen extends StatefulWidget {
  final AcademicCalendarEvent? event;
  final DateTime? initialDate;

  const AddEditAcademicCalendarScreen({
    super.key,
    this.event,
    this.initialDate,
  });

  @override
  State<AddEditAcademicCalendarScreen> createState() =>
      _AddEditAcademicCalendarScreenState();
}

class _AddEditAcademicCalendarScreenState
    extends State<AddEditAcademicCalendarScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late TextEditingController _attachmentUrlController;
  late TextEditingController _academicYearController;

  String _category = 'VACATION';
  late DateTime _startDate;
  late DateTime _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 14, minute: 0);
  bool _isAllDay = true;
  bool _isHoliday = true;
  String _targetAudience = 'ALL';
  List<String> _selectedClassIds = [];
  String _selectedColor = '#E53935';
  String _term = 'First Term';

  static const List<String> _categories = [
    'VACATION',
    'HOLIDAY',
    'EXAM',
    'EVENT',
    'MEETING',
    'SPORTS',
    'OTHER',
  ];

  static const List<String> _audiences = [
    'ALL',
    'STUDENT',
    'TEACHER',
    'STAFF',
  ];

  static const List<String> _terms = [
    'First Term',
    'Mid Term',
    'Final Term',
    'Full Year',
  ];

  static const List<Map<String, dynamic>> _colorPalette = [
    {'name': 'Red', 'hex': '#E53935', 'color': Color(0xFFE53935)},
    {'name': 'Purple', 'hex': '#8B5CF6', 'color': Color(0xFF8B5CF6)},
    {'name': 'Teal', 'hex': '#0D9488', 'color': Color(0xFF0D9488)},
    {'name': 'Blue', 'hex': '#2563EB', 'color': Color(0xFF2563EB)},
    {'name': 'Amber', 'hex': '#F59E0B', 'color': Color(0xFFF59E0B)},
    {'name': 'Emerald', 'hex': '#10B981', 'color': Color(0xFF10B981)},
    {'name': 'Pink', 'hex': '#EC4899', 'color': Color(0xFFEC4899)},
    {'name': 'Indigo', 'hex': '#6366F1', 'color': Color(0xFF6366F1)},
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.event;

    if (ev != null) {
      _titleController = TextEditingController(text: ev.title);
      _descController = TextEditingController(text: ev.description ?? '');
      _locationController = TextEditingController(text: ev.location ?? '');
      _attachmentUrlController =
          TextEditingController(text: ev.attachmentUrl ?? '');
      _academicYearController =
          TextEditingController(text: ev.academicYear ?? '2026-2027');
      _category = ev.category.toUpperCase();
      _startDate = ev.startDate;
      _endDate = ev.endDate;
      _isAllDay = ev.isAllDay;
      _isHoliday = ev.isHoliday;
      _targetAudience = ev.targetAudience.toUpperCase();
      _selectedClassIds = List.from(ev.classIds);
      _selectedColor = ev.color ?? '#E53935';
      _term = ev.term ?? 'First Term';

      if (ev.startTime != null && ev.startTime!.contains(':')) {
        final parts = ev.startTime!.split(':');
        _startTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      if (ev.endTime != null && ev.endTime!.contains(':')) {
        final parts = ev.endTime!.split(':');
        _endTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 14,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    } else {
      final baseDate = widget.initialDate ?? DateTime(2026, 6, 1);
      _titleController = TextEditingController();
      _descController = TextEditingController();
      _locationController = TextEditingController(text: 'Main Auditorium');
      _attachmentUrlController = TextEditingController();
      _academicYearController = TextEditingController(text: '2026-2027');
      _startDate = baseDate;
      _endDate = baseDate.add(const Duration(days: 14));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schoolId = context.read<AuthNotifier>().user?.schoolId;
      if (schoolId != null &&
          context.read<ClassSetupNotifier>().classes.isEmpty) {
        context.read<ClassSetupNotifier>().fetchClasses(schoolId);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _attachmentUrlController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  void _fillSampleData() {
    setState(() {
      _titleController.text = 'Summer Vacation 2026';
      _descController.text = 'School will remain closed for summer recess.';
      _category = 'VACATION';
      _startDate = DateTime(2026, 6, 1);
      _endDate = DateTime(2026, 6, 15);
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 14, minute: 0);
      _isAllDay = true;
      _isHoliday = true;
      _targetAudience = 'ALL';
      _selectedColor = '#E53935';
      _locationController.text = 'Main Auditorium';
      _attachmentUrlController.text =
          'https://example.com/uploads/academic-calendar-2026.pdf';
      _academicYearController.text = '2026-2027';
      _term = 'First Term';
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null &&
        result.files.isNotEmpty &&
        result.files.first.path != null) {
      if (!mounted) return;
      final file = File(result.files.first.path!);
      final provider = context.read<AcademicCalendarProvider>();
      final uploadedUrl = await provider.uploadAttachment(file);

      if (uploadedUrl != null && mounted) {
        setState(() {
          _attachmentUrlController.text = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload file. You can enter URL manually.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AcademicCalendarProvider>();
    final authNotifier = context.read<AuthNotifier>();
    final schoolId = authNotifier.user?.schoolId;

    final eventToSave = AcademicCalendarEvent(
      id: widget.event?.id ?? '',
      schoolId: widget.event?.schoolId ?? schoolId ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      category: _category,
      startDate: _startDate,
      endDate: _endDate,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      isAllDay: _isAllDay,
      isHoliday: _isHoliday,
      targetAudience: _targetAudience,
      classIds: _selectedClassIds,
      color: _selectedColor,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      attachmentUrl: _attachmentUrlController.text.trim().isEmpty
          ? null
          : _attachmentUrlController.text.trim(),
      academicYear: _academicYearController.text.trim().isEmpty
          ? null
          : _academicYearController.text.trim(),
      term: _term,
    );

    bool success = false;
    if (widget.event == null) {
      success = await provider.createEvent(eventToSave, schoolId: schoolId);
    } else {
      success = await provider.updateEvent(
        widget.event!.id,
        eventToSave.toCreateJson(),
      );
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event == null
                  ? 'Academic calendar event created successfully!'
                  : 'Academic calendar event updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to save event'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classes = context.watch<ClassSetupNotifier>().classes;
    final isSubmitting = context.watch<AcademicCalendarProvider>().isSubmitting;
    final isUploading = context.watch<AcademicCalendarProvider>().isUploading;
    final uploadProgress =
        context.watch<AcademicCalendarProvider>().uploadProgress;

    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.event == null ? 'Create Calendar Event' : 'Edit Calendar Event',
        ),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        actions: [
          if (widget.event == null)
            TextButton.icon(
              onPressed: _fillSampleData,
              icon: const Icon(Icons.auto_fix_high_rounded,
                  color: Colors.white, size: 16),
              label: const Text(
                'Fill Sample',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Field
            _buildCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event Title *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Summer Vacation 2026',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter event title';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Category & Holiday
            _buildCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _category == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _category = cat;
                              if (cat == 'VACATION' || cat == 'HOLIDAY') {
                                _isHoliday = true;
                              }
                            });
                          }
                        },
                        selectedColor: AppColors.primaryAdmin,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey.shade300 : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Mark as Official Holiday',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Institution will remain closed during this period',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    value: _isHoliday,
                    activeThumbColor: const Color(0xFFEF4444),
                    onChanged: (val) => setState(() => _isHoliday = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Dates & Times
            _buildCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date & Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickStartDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: AppColors.primaryAdmin,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        dateFormat.format(_startDate),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: _pickEndDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.event_available_rounded,
                                      size: 14,
                                      color: AppColors.primaryAdmin,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        dateFormat.format(_endDate),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'All Day Event',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    value: _isAllDay,
                    activeThumbColor: AppColors.primaryAdmin,
                    onChanged: (val) => setState(() => _isAllDay = val),
                  ),
                  if (!_isAllDay) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickStartTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Time',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color: AppColors.primaryAdmin,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatTime(_startTime),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _pickEndTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End Time',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_filled_rounded,
                                        size: 14,
                                        color: AppColors.primaryAdmin,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatTime(_endTime),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Target Audience & Classes
            _buildCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Target Audience',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _audiences.map((aud) {
                      final isSelected = _targetAudience == aud;
                      return ChoiceChip(
                        label: Text(aud),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _targetAudience = aud;
                            });
                          }
                        },
                        selectedColor: AppColors.primaryAdmin,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey.shade300 : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                  if (classes.isNotEmpty) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Specific Classes (Optional)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedClassIds.length == classes.length) {
                                _selectedClassIds.clear();
                              } else {
                                _selectedClassIds =
                                    classes.map((c) => c.id).toList();
                              }
                            });
                          },
                          child: Text(
                            _selectedClassIds.length == classes.length
                                ? 'Deselect All'
                                : 'Select All',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: classes.map((c) {
                        final isSel = _selectedClassIds.contains(c.id);
                        return FilterChip(
                          label: Text(c.name),
                          selected: isSel,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedClassIds.add(c.id);
                              } else {
                                _selectedClassIds.remove(c.id);
                              }
                            });
                          },
                          selectedColor:
                              AppColors.primaryAdmin.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primaryAdmin,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel
                                ? AppColors.primaryAdmin
                                : (isDark ? Colors.grey.shade300 : Colors.black87),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Color Palette Picker
            _buildCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Color Accent',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _colorPalette.map((item) {
                      final hex = item['hex'] as String;
                      final color = item['color'] as Color;
                      final isSelected =
                          _selectedColor.toUpperCase() == hex.toUpperCase();
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = hex),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Academic Year & Term & Location
            _buildCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Academic Term & Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Academic Year',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _academicYearController,
                              decoration: InputDecoration(
                                hintText: '2026-2027',
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Term',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _terms.contains(_term) ? _term : _terms.first,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              items: _terms.map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(t, style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _term = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Main Auditorium, Campus Ground',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.location_on_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Description
            _buildCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description / Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter details about this event or notice...',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Attachment URL / File upload
            _buildCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Attachment Document / PDF',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primaryAdmin.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primaryAdmin,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        onPressed: isUploading ? null : _pickFile,
                        icon: isUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryAdmin,
                                ),
                              )
                            : const Icon(Icons.upload_file_rounded, size: 16),
                        label: Text(
                          isUploading ? 'Uploading...' : 'Pick & Upload',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (isUploading) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: uploadProgress > 0 ? uploadProgress : null,
                      backgroundColor: Colors.grey.shade200,
                      color: AppColors.primaryAdmin,
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _attachmentUrlController,
                    decoration: InputDecoration(
                      hintText: 'https://example.com/uploads/document.pdf',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.link_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save / Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAdmin,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.event == null
                            ? 'Create Academic Calendar Event'
                            : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: child,
    );
  }
}
