import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/models/academic_calendar_model.dart';
import 'package:smart_school/features/admin/providers/academic_calendar_provider.dart';
import 'package:smart_school/features/admin/screens/add_edit_academic_calendar_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AcademicCalendarDetailScreen extends StatelessWidget {
  final AcademicCalendarEvent event;
  final bool isReadOnly;

  const AcademicCalendarDetailScreen({
    super.key,
    required this.event,
    this.isReadOnly = false,
  });

  Future<void> _openAttachment(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open attachment URL')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext); // close dialog
              final provider = context.read<AcademicCalendarProvider>();
              final success = await provider.deleteEvent(event.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // close detail screen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.error ?? 'Failed to delete event'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = event.displayColor;
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');

    final timeStr = event.isAllDay
        ? 'All Day'
        : (event.startTime != null && event.endTime != null
            ? '${event.startTime} - ${event.endTime}'
            : (event.startTime ?? 'All Day'));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        actions: [
          if (!isReadOnly) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Event',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditAcademicCalendarScreen(event: event),
                  ),
                );
                if (result == true && context.mounted) {
                  Navigator.pop(context); // Close details so refreshed list shows
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Event',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (event.isHoliday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.beach_access_rounded,
                                size: 14,
                                color: Color(0xFFEF4444),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'OFFICIAL HOLIDAY',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (event.academicYear != null)
                        Text(
                          event.academicYear!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),

                  if (event.term != null && event.term!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Term: ${event.term}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Time & Date Section
            _buildSectionCard(
              context,
              isDark: isDark,
              title: 'Schedule & Time',
              icon: Icons.calendar_month_rounded,
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    isDark: isDark,
                    icon: Icons.date_range_rounded,
                    label: 'Start Date',
                    value: dateFormat.format(event.startDate),
                  ),
                  const Divider(height: 18),
                  _buildDetailRow(
                    context,
                    isDark: isDark,
                    icon: Icons.event_available_rounded,
                    label: 'End Date',
                    value: dateFormat.format(event.endDate),
                  ),
                  const Divider(height: 18),
                  _buildDetailRow(
                    context,
                    isDark: isDark,
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: timeStr,
                  ),
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const Divider(height: 18),
                    _buildDetailRow(
                      context,
                      isDark: isDark,
                      icon: Icons.location_on_rounded,
                      label: 'Location',
                      value: event.location!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Audience & Scope Section
            _buildSectionCard(
              context,
              isDark: isDark,
              title: 'Audience & Scope',
              icon: Icons.groups_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    context,
                    isDark: isDark,
                    icon: Icons.person_pin_rounded,
                    label: 'Target Audience',
                    value: event.targetAudience,
                  ),
                  if (event.classes.isNotEmpty) ...[
                    const Divider(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.class_rounded,
                          size: 18,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Applicable Classes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: event.classes
                                    .map(
                                      (c) => Chip(
                                        label: Text(
                                          c.name,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade100,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description Section
            if (event.description != null && event.description!.trim().isNotEmpty) ...[
              _buildSectionCard(
                context,
                isDark: isDark,
                title: 'Description & Notes',
                icon: Icons.description_rounded,
                child: Text(
                  event.description!.trim(),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Attachment Section
            if (event.attachmentUrl != null && event.attachmentUrl!.trim().isNotEmpty) ...[
              _buildSectionCard(
                context,
                isDark: isDark,
                title: 'Attached Document',
                icon: Icons.attach_file_rounded,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAdmin.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.primaryAdmin,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.attachmentUrl!.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.attachmentUrl!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAdmin,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _openAttachment(context, event.attachmentUrl!),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('Open'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Metadata / Created By
            if (event.createdBy != null) ...[
              _buildSectionCard(
                context,
                isDark: isDark,
                title: 'Created By',
                icon: Icons.person_outline_rounded,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryAdmin.withValues(alpha: 0.15),
                      backgroundImage: (event.createdBy?.avatar != null &&
                              event.createdBy!.avatar!.isNotEmpty)
                          ? NetworkImage(event.createdBy!.avatar!)
                          : null,
                      child: (event.createdBy?.avatar == null ||
                              event.createdBy!.avatar!.isEmpty)
                          ? Text(
                              (event.createdBy?.name.isNotEmpty == true)
                                  ? event.createdBy!.name[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryAdmin,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.createdBy!.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (event.createdBy?.role != null)
                            Text(
                              event.createdBy!.role!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (event.createdAt != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(event.createdAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryAdmin),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
