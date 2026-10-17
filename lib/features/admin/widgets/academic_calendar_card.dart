import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/models/academic_calendar_model.dart';

class AcademicCalendarCard extends StatelessWidget {
  final AcademicCalendarEvent event;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AcademicCalendarCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = event.displayColor;
    final dateFormat = DateFormat('MMM dd, yyyy');

    final dateRangeStr = event.startDateFormatted == event.endDateFormatted
        ? dateFormat.format(event.startDate)
        : '${dateFormat.format(event.startDate)} - ${dateFormat.format(event.endDate)}';

    final timeStr = event.isAllDay
        ? 'All Day'
        : (event.startTime != null && event.endTime != null
            ? '${event.startTime} - ${event.endTime}'
            : (event.startTime ?? 'All Day'));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Color Indicator Bar
                Container(
                  width: 5,
                  height: 90,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges Row
                      Row(
                        children: [
                          // Category Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (event.isHoliday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.beach_access_rounded,
                                    size: 12,
                                    color: Color(0xFFEF4444),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'HOLIDAY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (event.academicYear != null &&
                              event.academicYear!.isNotEmpty)
                            Text(
                              event.academicYear!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),

                      if (event.description != null &&
                          event.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Date & Time row
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateRangeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (event.location != null &&
                              event.location!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event.location!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          if (event.term != null && event.term!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 13,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event.term!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          if (event.attachmentUrl != null &&
                              event.attachmentUrl!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 13,
                                  color: AppColors.primaryAdmin,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Attachment',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryAdmin,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron icon
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
