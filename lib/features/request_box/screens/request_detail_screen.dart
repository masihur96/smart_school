import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/request_complaint_model.dart';

class RequestDetailScreen extends StatelessWidget {
  final RequestComplaintModel item;

  const RequestDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.isRequest ? 'Request Details' : 'Complaint Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status, Type & Priority Badges
            _buildBadgesHeader(isDark),
            const SizedBox(height: 16),

            // Title
            Text(
              item.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Category & Date Row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (item.createdAt != null) ...[
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(item.createdAt!),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Sender & Recipient Section
            _buildPartyCard(
              context: context,
              title: 'Sender (From)',
              user: item.sender,
              fallbackId: item.senderId,
              icon: Icons.person_outline,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildPartyCard(
              context: context,
              title: 'Recipient (To)',
              user: item.recipient,
              fallbackId: item.recipientId,
              targetRole: item.targetRole,
              icon: Icons.assignment_ind_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Description Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              color: isDark ? const Color(0xFF1E232E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 18,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      item.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resolution info if available
            if (item.status == 'RESOLVED' ||
                item.resolutionNote != null ||
                item.resolvedBy != null) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.green.shade300,
                  ),
                ),
                color: isDark
                    ? Colors.green.shade900.withAlpha(50)
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Resolution Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      if (item.resolutionNote != null &&
                          item.resolutionNote!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.resolutionNote!,
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                      if (item.resolvedBy != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Resolved by: ${item.resolvedBy!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      if (item.resolvedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Resolved on: ${DateFormat('MMM dd, yyyy • hh:mm a').format(item.resolvedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Attachments Section
            if (item.attachments.isNotEmpty) ...[
              const Text(
                'Attachments',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...item.attachments.map((url) => _buildAttachmentItem(context, url, isDark)),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesHeader(bool isDark) {
    Color typeColor =
        item.isRequest ? Colors.blue.shade700 : Colors.deepOrange.shade700;
    Color typeBg =
        item.isRequest ? Colors.blue.shade50 : Colors.deepOrange.shade50;
    if (isDark) {
      typeBg = typeColor.withAlpha(50);
    }

    Color priorityColor;
    switch (item.priority) {
      case 'URGENT':
        priorityColor = Colors.red.shade700;
        break;
      case 'HIGH':
        priorityColor = Colors.orange.shade800;
        break;
      case 'MEDIUM':
        priorityColor = Colors.amber.shade800;
        break;
      default:
        priorityColor = Colors.teal.shade700;
    }

    Color statusColor;
    Color statusBg;
    switch (item.status) {
      case 'RESOLVED':
        statusColor = Colors.green.shade800;
        statusBg = isDark ? Colors.green.shade900.withAlpha(60) : Colors.green.shade50;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue.shade800;
        statusBg = isDark ? Colors.blue.shade900.withAlpha(60) : Colors.blue.shade50;
        break;
      case 'REJECTED':
        statusColor = Colors.red.shade800;
        statusBg = isDark ? Colors.red.shade900.withAlpha(60) : Colors.red.shade50;
        break;
      default:
        statusColor = Colors.orange.shade800;
        statusBg = isDark ? Colors.orange.shade900.withAlpha(60) : Colors.orange.shade50;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Type Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: typeBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: typeColor.withAlpha(100), width: 1),
          ),
          child: Text(
            item.type,
            style: TextStyle(
              color: typeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        // Priority Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: priorityColor.withAlpha(25),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: priorityColor.withAlpha(100), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag, size: 12, color: priorityColor),
              const SizedBox(width: 4),
              Text(
                '${item.priority} PRIORITY',
                style: TextStyle(
                  color: priorityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withAlpha(100), width: 1),
          ),
          child: Text(
            item.status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartyCard({
    required BuildContext context,
    required String title,
    required RequestComplaintUser? user,
    String? fallbackId,
    String? targetRole,
    required IconData icon,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final name = user?.name ?? (targetRole != null ? 'Role: $targetRole' : 'N/A');
    final role = user?.role ?? targetRole;
    final designation = user?.designation;
    final avatar = user?.avatar;
    final email = user?.email;
    final phone = user?.phone;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      color: isDark ? const Color(0xFF1E232E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.primaryColor.withAlpha(30),
              backgroundImage: (avatar != null && avatar.isNotEmpty)
                  ? CachedNetworkImageProvider(avatar)
                  : null,
              child: (avatar == null || avatar.isEmpty)
                  ? Icon(icon, color: theme.primaryColor, size: 22)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (designation != null || role != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [if (designation != null) designation, if (role != null) role.toUpperCase()]
                          .join(' • '),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                  if (email != null || phone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [if (phone != null) phone, if (email != null) email].join(' | '),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(
      BuildContext context, String url, bool isDark) {
    final isImage = url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.webp') ||
        url.toLowerCase().endsWith('.gif');

    final fileName = url.split('/').last;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? const Color(0xFF1E232E) : Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final uri = Uri.tryParse(url);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                if (isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.image,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.insert_drive_file_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
