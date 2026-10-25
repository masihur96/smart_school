import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/request_complaint_model.dart';
import '../providers/request_complaint_provider.dart';

class RequestDetailScreen extends StatefulWidget {
  final Color scaffoldColor;
  final RequestComplaintModel item;

  const RequestDetailScreen({
    super.key,
    required this.item,
    required this.scaffoldColor,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late RequestComplaintModel _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  void _showChangeStatusDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String selectedStatus = _item.status;
    final noteController =
        TextEditingController(text: _item.resolutionNote ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final provider = context.watch<RequestComplaintProvider>();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.sync_alt, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Update Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select New Status *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusOptionChip(
                          label: 'PENDING',
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                          isSelected: selectedStatus == 'PENDING',
                          onTap: () =>
                              setModalState(() => selectedStatus = 'PENDING'),
                        ),
                        _buildStatusOptionChip(
                          label: 'IN_PROGRESS',
                          icon: Icons.run_circle_outlined,
                          color: Colors.blue,
                          isSelected: selectedStatus == 'IN_PROGRESS',
                          onTap: () => setModalState(
                              () => selectedStatus = 'IN_PROGRESS'),
                        ),
                        _buildStatusOptionChip(
                          label: 'RESOLVED',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          isSelected: selectedStatus == 'RESOLVED',
                          onTap: () =>
                              setModalState(() => selectedStatus = 'RESOLVED'),
                        ),
                        _buildStatusOptionChip(
                          label: 'REJECTED',
                          icon: Icons.cancel_outlined,
                          color: Colors.red,
                          isSelected: selectedStatus == 'REJECTED',
                          onTap: () =>
                              setModalState(() => selectedStatus = 'REJECTED'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Resolution Note / Remarks',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Leave application approved for 3 days.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E232E)
                            : Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: provider.isUpdatingStatus
                                ? null
                                : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: provider.isUpdatingStatus
                                ? null
                                : () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final nav = Navigator.of(ctx);

                                    final updated = await provider.updateStatus(
                                      id: _item.id,
                                      status: selectedStatus,
                                      resolutionNote:
                                          noteController.text.trim(),
                                    );

                                    if (!mounted) return;

                                    if (updated != null) {
                                      setState(() {
                                        _item = updated;
                                      });
                                      nav.pop();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Status updated to $selectedStatus successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      final err = provider.errorMessage ??
                                          'Failed to update status';
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(err),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: provider.isUpdatingStatus
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Update Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusOptionChip({
    required String label,
    required IconData icon,
    required MaterialColor color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color.shade700 : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color.shade700 : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color.shade900 : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.scaffoldColor,
        title: Text(
          _item.isRequest ? 'Request Details' : 'Complaint Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_alt),
            tooltip: 'Change Status',
            onPressed: _showChangeStatusDialog,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton.icon(
            onPressed: _showChangeStatusDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.sync_alt, size: 20),
            label: const Text(
              'Change Status',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
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
              _item.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Category & Date Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _item.category,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_item.createdAt != null) ...[
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(_item.createdAt!),
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
              user: _item.sender,
              fallbackId: _item.senderId,
              icon: Icons.person_outline,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildPartyCard(
              context: context,
              title: 'Recipient (To)',
              user: _item.recipient,
              fallbackId: _item.recipientId,
              targetRole: _item.targetRole,
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
                      _item.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resolution info if available
            if (_item.status == 'RESOLVED' ||
                _item.status == 'REJECTED' ||
                _item.resolutionNote != null ||
                _item.resolvedBy != null) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _item.status == 'REJECTED'
                        ? Colors.red.shade300
                        : Colors.green.shade300,
                  ),
                ),
                color: isDark
                    ? (_item.status == 'REJECTED'
                        ? Colors.red.shade900.withAlpha(50)
                        : Colors.green.shade900.withAlpha(50))
                    : (_item.status == 'REJECTED'
                        ? Colors.red.shade50
                        : Colors.green.shade50),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _item.status == 'REJECTED'
                                ? Icons.cancel_outlined
                                : Icons.check_circle_outline,
                            color: _item.status == 'REJECTED'
                                ? Colors.red
                                : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _item.status == 'REJECTED'
                                ? 'Rejection Details'
                                : 'Resolution Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _item.status == 'REJECTED'
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      if (_item.resolutionNote != null &&
                          _item.resolutionNote!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _item.resolutionNote!,
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                      if (_item.resolvedBy != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Resolved by: ${_item.resolvedBy!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      if (_item.resolvedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Resolved on: ${DateFormat('MMM dd, yyyy • hh:mm a').format(_item.resolvedAt!)}',
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
            if (_item.attachments.isNotEmpty) ...[
              const Text(
                'Attachments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ..._item.attachments.map(
                (url) => _buildAttachmentItem(context, url, isDark),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesHeader(bool isDark) {
    Color typeColor = _item.isRequest
        ? Colors.blue.shade700
        : Colors.deepOrange.shade700;
    Color typeBg = _item.isRequest
        ? Colors.blue.shade50
        : Colors.deepOrange.shade50;
    if (isDark) {
      typeBg = typeColor.withAlpha(50);
    }

    Color priorityColor;
    switch (_item.priority) {
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
    switch (_item.status) {
      case 'RESOLVED':
        statusColor = Colors.green.shade800;
        statusBg = isDark
            ? Colors.green.shade900.withAlpha(60)
            : Colors.green.shade50;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue.shade800;
        statusBg = isDark
            ? Colors.blue.shade900.withAlpha(60)
            : Colors.blue.shade50;
        break;
      case 'REJECTED':
        statusColor = Colors.red.shade800;
        statusBg = isDark
            ? Colors.red.shade900.withAlpha(60)
            : Colors.red.shade50;
        break;
      default:
        statusColor = Colors.orange.shade800;
        statusBg = isDark
            ? Colors.orange.shade900.withAlpha(60)
            : Colors.orange.shade50;
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
            _item.type,
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
                '${_item.priority} PRIORITY',
                style: TextStyle(
                  color: priorityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Status Badge (Clickable to change status)
        InkWell(
          onTap: _showChangeStatusDialog,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withAlpha(120), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _item.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit_outlined, size: 12, color: statusColor),
              ],
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
    final name =
        user?.name ?? (targetRole != null ? 'Role: $targetRole' : 'N/A');
    final role = user?.role ?? targetRole;
    final designation = user?.designation;
    final avatar = user?.avatar;
    final email = user?.email;
    final phone = user?.phone;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
                      [
                        if (designation != null) designation,
                        if (role != null) role.toUpperCase(),
                      ].join(' • '),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                  if (email != null || phone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (phone != null) phone,
                        if (email != null) email,
                      ].join(' | '),
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

  Widget _buildAttachmentItem(BuildContext context, String url, bool isDark) {
    final isImage =
        url.toLowerCase().endsWith('.png') ||
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
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.image, size: 32, color: Colors.grey),
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
                const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
