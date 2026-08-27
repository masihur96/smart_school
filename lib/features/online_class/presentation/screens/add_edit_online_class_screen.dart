import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/admin/providers/teacher_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/online_class/providers/online_class_provider.dart';
import 'package:smart_school/models/online_class_model.dart';

enum MeetingCategory { onlineClass, teacherMeeting }

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

  MeetingCategory _meetingCategory = MeetingCategory.onlineClass;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedEndTime;

  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  List<String> _selectedTeacherUuids = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      final schoolId = user?.schoolId ?? '';
      if (schoolId.isNotEmpty) {
        final classNotifier = context.read<ClassSetupNotifier>();
        if (classNotifier.classes.isEmpty) {
          classNotifier.fetchClasses(schoolId);
        }
        final subjectNotifier = context.read<SubjectSetupNotifier>();
        if (subjectNotifier.subjects.isEmpty) {
          subjectNotifier.fetchSubjects(schoolId);
        }
      }
      final sectionNotifier = context.read<SectionSetupNotifier>();
      if (sectionNotifier.sections.isEmpty) {
        sectionNotifier.fetchSections();
      }
      final teacherProvider = context.read<TeachersNotifier>();
      if (teacherProvider.teachers.isEmpty) {
        teacherProvider.fetchTeachers();
      }
    });

    if (widget.onlineClass != null) {
      final item = widget.onlineClass!;
      _titleController.text = item.title;
      _descController.text = item.description;
      _linkController.text = item.meetLink;
      _selectedDate = item.scheduledTime;
      _selectedTime = TimeOfDay.fromDateTime(item.scheduledTime);
      _selectedEndTime = TimeOfDay.fromDateTime(
        item.scheduledTime.add(const Duration(hours: 1)),
      );
      _selectedClassId = item.classId;
      _selectedSectionId = item.sectionId;
      _selectedSubjectId = item.subjectId;

      // Determine meeting type based on classId presence
      if (item.classId == null || item.classId!.isEmpty) {
        _meetingCategory = MeetingCategory.teacherMeeting;
      } else {
        _meetingCategory = MeetingCategory.onlineClass;
      }
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      final nowPlusHour = DateTime.now().add(const Duration(hours: 1));
      _selectedEndTime = TimeOfDay.fromDateTime(nowPlusHour);
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

  String? _calculateDuration() {
    if (_selectedTime == null || _selectedEndTime == null) return null;
    final startMins = _selectedTime!.hour * 60 + _selectedTime!.minute;
    final endMins = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
    int diffMins = endMins - startMins;
    if (diffMins <= 0) diffMins += 24 * 60; // Handle overnight meetings

    final hours = diffMins ~/ 60;
    final mins = diffMins % 60;

    if (hours > 0 && mins > 0) {
      return '$hours hr $mins mins';
    } else if (hours > 0) {
      return '$hours hr${hours > 1 ? 's' : ''}';
    } else {
      return '$mins mins';
    }
  }

  Map<String, dynamic> _getPlatformInfo(String url) {
    final lower = url.toLowerCase().trim();
    if (lower.contains('meet.google.com')) {
      return {
        'label': 'Google Meet',
        'icon': Icons.video_camera_front_rounded,
        'color': Colors.green.shade700,
        'bgColor': Colors.green.shade50,
      };
    }
    if (lower.contains('zoom.us')) {
      return {
        'label': 'Zoom Meeting',
        'icon': Icons.videocam_rounded,
        'color': Colors.blue.shade700,
        'bgColor': Colors.blue.shade50,
      };
    }
    if (lower.contains('teams.microsoft.com') ||
        lower.contains('teams.live.com')) {
      return {
        'label': 'Microsoft Teams',
        'icon': Icons.groups_rounded,
        'color': Colors.deepPurple.shade700,
        'bgColor': Colors.deepPurple.shade50,
      };
    }
    if (lower.contains('webex.com')) {
      return {
        'label': 'Cisco Webex',
        'icon': Icons.video_call_rounded,
        'color': Colors.teal.shade700,
        'bgColor': Colors.teal.shade50,
      };
    }
    return {
      'label': 'Online Meeting Link',
      'icon': Icons.link_rounded,
      'color': Colors.indigo.shade700,
      'bgColor': Colors.indigo.shade50,
    };
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null ||
          _selectedTime == null ||
          _selectedEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select date, start time, and end time'),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final isEditing = widget.onlineClass != null;
      final dateStr = _selectedDate!.toUtc().toIso8601String();
      final startTimeStr = _selectedTime!.format(context);
      final endTimeStr = _selectedEndTime!.format(context);

      final classId = _meetingCategory == MeetingCategory.onlineClass
          ? _selectedClassId
          : null;
      final sectionId = _meetingCategory == MeetingCategory.onlineClass
          ? _selectedSectionId
          : null;
      final subjectId = _meetingCategory == MeetingCategory.onlineClass
          ? _selectedSubjectId
          : null;

      List<String>? participants = [];
      if (_meetingCategory == MeetingCategory.onlineClass) {
        if (classId != null) {
          final studentProvider = context.read<StudentsNotifier>();
          await studentProvider.fetchStudentsBySection(
            classId: classId,
            sectionId: sectionId,
          );
          participants = studentProvider.students.map((e) => e.userId).toList();
        }
      } else {
        participants = _selectedTeacherUuids.isNotEmpty
            ? _selectedTeacherUuids
            : null;
      }

      if (!isEditing) {
        final success = await context
            .read<OnlineClassProvider>()
            .createOnlineClass(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              meetLink: _linkController.text.trim(),
              date: dateStr,
              startTime: startTimeStr,
              endTime: endTimeStr,
              classId: classId,
              sectionId: sectionId,
              subjectId: subjectId,
              participantUuids: participants,
            );

        setState(() => _isLoading = false);

        if (success && mounted) {
          Navigator.pop(context, true);
        } else if (mounted) {
          final error = context.read<OnlineClassProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error ??
                    (_meetingCategory == MeetingCategory.onlineClass
                        ? 'Failed to create online class'
                        : 'Failed to create teacher meeting'),
              ),
            ),
          );
        }
      } else {
        final success = await context
            .read<OnlineClassProvider>()
            .updateOnlineClass(
              id: widget.onlineClass!.id,
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              meetLink: _linkController.text.trim(),
              date: dateStr,
              startTime: startTimeStr,
              endTime: endTimeStr,
              classId: classId,
              sectionId: sectionId,
              subjectId: subjectId,
              participantUuids: participants,
            );

        setState(() => _isLoading = false);

        if (success && mounted) {
          Navigator.pop(context, true);
        } else if (mounted) {
          final error = context.read<OnlineClassProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error ??
                    (_meetingCategory == MeetingCategory.onlineClass
                        ? 'Failed to update online class'
                        : 'Failed to update teacher meeting'),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryThemeColor = widget.isAdminOrTeacher
        ? AppColors.primaryAdmin
        : AppColors.primaryTeacher;

    final isEdit = widget.onlineClass != null;
    final titleText = isEdit
        ? (_meetingCategory == MeetingCategory.onlineClass
              ? 'Edit Online Class'
              : 'Edit Teacher Meeting')
        : (_meetingCategory == MeetingCategory.onlineClass
              ? 'Schedule Online Class'
              : 'Schedule Teacher Meeting');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryThemeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Segmented Category Selection Header ────────────────────────
              _buildMeetingTypeSelector(primaryThemeColor, isDark),
              const SizedBox(height: 20),

              // ── General Details Card ──────────────────────────────────────
              _buildCardSection(
                isDark: isDark,
                title: _meetingCategory == MeetingCategory.onlineClass
                    ? 'Class Info'
                    : 'Meeting Info',
                icon: _meetingCategory == MeetingCategory.onlineClass
                    ? Icons.school_outlined
                    : Icons.meeting_room_outlined,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: _meetingCategory == MeetingCategory.onlineClass
                        ? 'Class Title'
                        : 'Meeting Title',
                    hint: _meetingCategory == MeetingCategory.onlineClass
                        ? 'e.g., Mathematics Chapter 1'
                        : 'e.g., Faculty Weekly Sync & Planning',
                    icon: Icons.title_rounded,
                    isDark: isDark,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descController,
                    label: 'Description',
                    hint: _meetingCategory == MeetingCategory.onlineClass
                        ? 'Optional class agenda or instructions...'
                        : 'Optional meeting agenda, notes, or target topics...',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Academic vs Teacher Target Card ───────────────────────────
              if (_meetingCategory == MeetingCategory.onlineClass)
                _buildCardSection(
                  isDark: isDark,
                  title: 'Academic Details',
                  icon: Icons.menu_book_outlined,
                  children: [_buildAcademicDropdowns(isDark)],
                )
              else
                _buildCardSection(
                  isDark: isDark,
                  title: 'Select Participants (Teachers/Staff)',
                  icon: Icons.groups_outlined,
                  children: [_buildTeacherSelection(isDark, primaryThemeColor)],
                ),
              const SizedBox(height: 20),

              // ── Date & Time Schedule Card ──────────────────────────────────
              _buildCardSection(
                isDark: isDark,
                title: 'Schedule Date & Time',
                icon: Icons.event_available_outlined,
                children: [
                  _buildDateTimePicker(
                    label: 'Meeting Date',
                    value: _selectedDate != null
                        ? DateFormat(
                            'EEEE, MMM dd, yyyy',
                          ).format(_selectedDate!)
                        : 'Select Date',
                    icon: Icons.calendar_month_rounded,
                    onTap: _pickDate,
                    isDark: isDark,
                    primaryColor: primaryThemeColor,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePicker(
                          label: 'Start Time',
                          value: _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Select Start Time',
                          icon: Icons.access_time_rounded,
                          onTap: _pickTime,
                          isDark: isDark,
                          primaryColor: primaryThemeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimePicker(
                          label: 'End Time',
                          value: _selectedEndTime != null
                              ? _selectedEndTime!.format(context)
                              : 'Select End Time',
                          icon: Icons.update_rounded,
                          onTap: _pickEndTime,
                          isDark: isDark,
                          primaryColor: primaryThemeColor,
                        ),
                      ),
                    ],
                  ),
                  if (_calculateDuration() != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryThemeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: primaryThemeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Estimated Duration: ${_calculateDuration()}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: primaryThemeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // ── Meeting Link Card ──────────────────────────────────────────
              _buildCardSection(
                isDark: isDark,
                title: 'Virtual Meeting Link',
                icon: Icons.videocam_outlined,
                children: [
                  _buildTextField(
                    controller: _linkController,
                    label: 'Meeting Link / URL',
                    hint: 'e.g. https://meet.google.com/xxx-xxxx-xxx',
                    icon: Icons.link_rounded,
                    isDark: isDark,
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Meeting link is required';
                      }
                      final lower = val.trim().toLowerCase();
                      if (!lower.startsWith('http://') &&
                          !lower.startsWith('https://')) {
                        return 'Please enter a valid URL (starting with https://)';
                      }
                      return null;
                    },
                  ),
                  if (_linkController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final pInfo = _getPlatformInfo(_linkController.text);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: pInfo['bgColor'] as Color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (pInfo['color'] as Color).withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                pInfo['icon'] as IconData,
                                size: 16,
                                color: pInfo['color'] as Color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Platform: ${pInfo['label']}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: pInfo['color'] as Color,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),

              // ── Submit Button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : Icon(
                          isEdit
                              ? Icons.check_circle
                              : Icons.video_call_rounded,
                          color: Colors.white,
                        ),
                  label: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isEdit
                              ? (_meetingCategory == MeetingCategory.onlineClass
                                    ? 'Update Online Class'
                                    : 'Update Teacher Meeting')
                              : (_meetingCategory == MeetingCategory.onlineClass
                                    ? 'Save & Schedule Class'
                                    : 'Save & Schedule Meeting'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryThemeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Meeting Type Selector Widget ───────────────────────────────────────────

  Widget _buildMeetingTypeSelector(Color primaryThemeColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeSegmentTab(
              category: MeetingCategory.onlineClass,
              label: 'Online Class',
              icon: Icons.school_rounded,
              primaryColor: primaryThemeColor,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildTypeSegmentTab(
              category: MeetingCategory.teacherMeeting,
              label: 'Teacher Meeting',
              icon: Icons.record_voice_over_rounded,
              primaryColor: primaryThemeColor,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegmentTab({
    required MeetingCategory category,
    required String label,
    required IconData icon,
    required Color primaryColor,
    required bool isDark,
  }) {
    final isSelected = _meetingCategory == category;

    return GestureDetector(
      onTap: () {
        if (_meetingCategory != category) {
          setState(() {
            _meetingCategory = category;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.grey.shade800 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.grey.shade900)
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card Section Container ─────────────────────────────────────────────────

  Widget _buildCardSection({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: widget.isAdminOrTeacher
                    ? AppColors.primaryAdmin
                    : AppColors.primaryTeacher,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ── Text Field Widget ──────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required bool isDark,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontSize: 14.5,
        color: isDark ? Colors.white : Colors.grey.shade900,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.isAdminOrTeacher
                ? AppColors.primaryAdmin
                : AppColors.primaryTeacher,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      ),
    );
  }

  // ── Date/Time Picker Card Button ───────────────────────────────────────────

  Widget _buildDateTimePicker({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey.shade900,
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

  // ── Teacher Meeting Target Notice ──────────────────────────────────────────

  Widget _buildTeacherMeetingNotice(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.record_voice_over_rounded,
              size: 22,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faculty & Staff Meeting',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This meeting will be broadcasted to all teachers and staff members. Class, Section, and Subject selections are not required.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Teacher Selection for Meetings ──────────────────────────────────────────

  Widget _buildTeacherSelection(bool isDark, Color primaryColor) {
    final teacherProvider = context.watch<TeachersNotifier>();

    return InkWell(
      onTap: () =>
          _showTeacherSelectionDialog(teacherProvider, isDark, primaryColor),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, size: 20, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTeacherUuids.isEmpty
                    ? 'Select teachers...'
                    : '${_selectedTeacherUuids.length} teacher(s) selected',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedTeacherUuids.isEmpty
                      ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600)
                      : (isDark ? Colors.white : Colors.grey.shade900),
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _showTeacherSelectionDialog(
    TeachersNotifier provider,
    bool isDark,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
              title: Text(
                'Select Teachers',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: provider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : provider.teachers.isEmpty
                    ? Center(
                        child: Text(
                          'No teachers found',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.teachers.length,
                        itemBuilder: (context, index) {
                          final teacher = provider.teachers[index];
                          final isSelected = _selectedTeacherUuids.contains(
                            teacher.userId,
                          );
                          return CheckboxListTile(
                            activeColor: primaryColor,
                            checkColor: Colors.white,
                            title: Text(
                              teacher.user?.name ?? 'Unknown Teacher',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            value: isSelected,
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  _selectedTeacherUuids.add(teacher.userId);
                                } else {
                                  _selectedTeacherUuids.remove(teacher.userId);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Academic Dropdowns ─────────────────────────────────────────────────────

  Widget _buildAcademicDropdowns(bool isDark) {
    final classSetup = context.watch<ClassSetupNotifier>();
    final sectionSetup = context.watch<SectionSetupNotifier>();
    final subjectSetup = context.watch<SubjectSetupNotifier>();

    // Section filtering with fallback
    var availableSections = sectionSetup.sections
        .where(
          (s) =>
              _selectedClassId == null ||
              s.classId.isEmpty ||
              s.classId == _selectedClassId,
        )
        .toList();
    if (availableSections.isEmpty && sectionSetup.sections.isNotEmpty) {
      availableSections = sectionSetup.sections;
    }

    // Subject filtering with fallback
    var availableSubjects = subjectSetup.subjects
        .where(
          (s) =>
              _selectedClassId == null ||
              s.classId.isEmpty ||
              s.classId == _selectedClassId,
        )
        .toList();
    if (availableSubjects.isEmpty && subjectSetup.subjects.isNotEmpty) {
      availableSubjects = subjectSetup.subjects;
    }

    final validClassId = classSetup.classes.any((c) => c.id == _selectedClassId)
        ? _selectedClassId
        : null;
    final validSectionId =
        availableSections.any((s) => s.id == _selectedSectionId)
        ? _selectedSectionId
        : null;
    final validSubjectId =
        availableSubjects.any((s) => s.id == _selectedSubjectId)
        ? _selectedSubjectId
        : null;

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: validClassId,
          decoration: _buildInputDecoration(
            'Class',
            Icons.class_rounded,
            isDark,
          ),
          dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
          hint: classSetup.isLoading ? const Text('Loading classes...') : null,
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
          validator: (val) =>
              _meetingCategory == MeetingCategory.onlineClass && val == null
              ? 'Please select a class'
              : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: validSectionId,
          decoration: _buildInputDecoration(
            'Section',
            Icons.groups_rounded,
            isDark,
          ),
          dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
          hint: sectionSetup.isLoading
              ? const Text('Loading sections...')
              : (availableSections.isEmpty
                    ? const Text('No sections available')
                    : null),
          items: availableSections.map((s) {
            return DropdownMenuItem(value: s.id, child: Text(s.name));
          }).toList(),
          onChanged: (val) => setState(() => _selectedSectionId = val),
          validator: (val) =>
              _meetingCategory == MeetingCategory.onlineClass && val == null
              ? 'Please select a section'
              : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: validSubjectId,
          decoration: _buildInputDecoration(
            'Subject',
            Icons.book_rounded,
            isDark,
          ),
          dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
          hint: subjectSetup.isLoading
              ? const Text('Loading subjects...')
              : (availableSubjects.isEmpty
                    ? const Text('No subjects available')
                    : null),
          items: availableSubjects.map((s) {
            return DropdownMenuItem(
              value: s.id,
              child: Text(s.name + (s.code.isNotEmpty ? ' (${s.code})' : '')),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedSubjectId = val),
          validator: (val) =>
              _meetingCategory == MeetingCategory.onlineClass && val == null
              ? 'Please select a subject'
              : null,
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon,
    bool isDark,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: widget.isAdminOrTeacher
              ? AppColors.primaryAdmin
              : AppColors.primaryTeacher,
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
    );
  }
}
