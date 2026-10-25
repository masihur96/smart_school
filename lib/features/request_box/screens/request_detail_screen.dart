import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
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
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _pendingAttachments = [];
  bool _isUploadingAttachment = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLatestDetails();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestDetails() async {
    final updated = await context
        .read<RequestComplaintProvider>()
        .fetchRequestComplaintDetail(_item.id);
    if (updated != null && mounted) {
      setState(() {
        _item = updated;
      });
    }
  }

  Future<void> _pickAttachmentFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        if (!mounted) return;
        final file = File(result.files.first.path!);
        setState(() => _isUploadingAttachment = true);

        final url =
            await context.read<RequestComplaintProvider>().uploadAttachment(file);

        if (url != null && mounted) {
          setState(() {
            _pendingAttachments.add(url);
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload file attachment.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }

  Future<void> _pickAttachmentImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked != null) {
        if (!mounted) return;
        final file = File(picked.path);
        setState(() => _isUploadingAttachment = true);

        final url =
            await context.read<RequestComplaintProvider>().uploadAttachment(file);

        if (url != null && mounted) {
          setState(() {
            _pendingAttachments.add(url);
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    final attachmentsToSend = List<String>.from(_pendingAttachments);
    _commentController.clear();
    setState(() {
      _pendingAttachments.clear();
    });

    final provider = context.read<RequestComplaintProvider>();
    final success = await provider.addComment(
      id: _item.id,
      message: text.isNotEmpty ? text : 'Shared an attachment',
      attachments: attachmentsToSend,
    );

    if (mounted) {
      if (success) {
        await _loadLatestDetails();
        // Scroll down to the newest comment
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to send comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.sync_alt,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
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
                    const SizedBox(height: 20),
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
    final provider = context.watch<RequestComplaintProvider>();
    final currentUser = context.watch<AuthNotifier>().user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.scaffoldColor,
        elevation: 0,
        title: Text(
          _item.isRequest ? 'Request Details' : 'Complaint Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadLatestDetails,
          ),
          IconButton(
            icon: const Icon(Icons.sync_alt),
            tooltip: 'Change Status',
            onPressed: _showChangeStatusDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Main Scrollable Details & Thread
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadLatestDetails,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview & Status Card
                    _buildOverviewCard(isDark, theme),
                    const SizedBox(height: 16),

                    // Participants Route Card (From -> To)
                    _buildParticipantsCard(isDark, theme),
                    const SizedBox(height: 16),

                    // Description Card
                    _buildDescriptionCard(isDark, theme),
                    const SizedBox(height: 16),

                    // Resolution Info Card (if resolved/rejected or note exists)
                    if (_item.status == 'RESOLVED' ||
                        _item.status == 'REJECTED' ||
                        _item.resolutionNote != null ||
                        _item.resolvedBy != null) ...[
                      _buildResolutionCard(isDark, theme),
                      const SizedBox(height: 16),
                    ],

                    // Original Attachments
                    if (_item.attachments.isNotEmpty) ...[
                      _buildAttachmentsSection(isDark, theme),
                      const SizedBox(height: 20),
                    ],

                    // Discussion Thread Section
                    _buildDiscussionThread(isDark, theme, currentUser?.id),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Sticky Comment Input Bar at Bottom
          _buildCommentInputBar(isDark, theme, provider),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(bool isDark, ThemeData theme) {
    Color typeColor = _item.isRequest
        ? Colors.blue.shade700
        : Colors.deepOrange.shade700;
    Color typeBg = _item.isRequest
        ? Colors.blue.shade50
        : Colors.deepOrange.shade50;
    if (isDark) typeBg = typeColor.withAlpha(40);

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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      color: isDark ? const Color(0xFF1E232E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row of Badges
            Row(
              children: [
                // Type Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: typeColor.withAlpha(80)),
                  ),
                  child: Text(
                    _item.type,
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Category Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _item.category,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Priority Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 12, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        _item.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Status Badge (Interactive)
                InkWell(
                  onTap: _showChangeStatusDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withAlpha(140)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _item.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 11, color: statusColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              _item.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 10),

            // Metadata row: Time & ID
            Row(
              children: [
                if (_item.createdAt != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(_item.createdAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const Spacer(),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _item.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ID copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${_item.id.length > 8 ? _item.id.substring(0, 8) : _item.id}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.copy, size: 12, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsCard(bool isDark, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      color: isDark ? const Color(0xFF1E232E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, size: 18, color: theme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Communication Route',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                // Sender Side
                Expanded(
                  child: _buildParticipantColumn(
                    label: 'From (Sender)',
                    user: _item.sender,
                    fallbackId: _item.senderId,
                    isDark: isDark,
                    theme: theme,
                    iconColor: Colors.blue,
                  ),
                ),

                // Arrow Divider
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ),

                // Recipient Side
                Expanded(
                  child: _buildParticipantColumn(
                    label: 'To (Recipient)',
                    user: _item.recipient,
                    fallbackId: _item.recipientId,
                    targetRole: _item.targetRole,
                    isDark: isDark,
                    theme: theme,
                    iconColor: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantColumn({
    required String label,
    required RequestComplaintUser? user,
    String? fallbackId,
    String? targetRole,
    required bool isDark,
    required ThemeData theme,
    required MaterialColor iconColor,
  }) {
    final name =
        user?.name ?? (targetRole != null ? 'Role: $targetRole' : 'N/A');
    final role = user?.role ?? targetRole;
    final avatar = user?.avatar;
    final designation = user?.designation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withAlpha(30),
              backgroundImage: (avatar != null && avatar.isNotEmpty)
                  ? CachedNetworkImageProvider(avatar)
                  : null,
              child: (avatar == null || avatar.isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: iconColor.shade800,
                        fontSize: 13,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    [
                      if (role != null) role.toUpperCase(),
                      if (designation != null && designation.isNotEmpty)
                        designation,
                    ].join(' • '),
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
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(bool isDark, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
                  Icons.notes,
                  size: 18,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Details & Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 20),
            SelectableText(
              _item.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionCard(bool isDark, ThemeData theme) {
    final isRejected = _item.status == 'REJECTED';
    final cardColor = isRejected ? Colors.red : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: cardColor.withAlpha(isDark ? 30 : 15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withAlpha(isDark ? 80 : 50),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRejected ? Icons.cancel_outlined : Icons.check_circle_outline,
                color: isRejected ? Colors.red.shade700 : Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isRejected ? 'Rejection Notes' : 'Resolution Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color:
                      isRejected ? Colors.red.shade800 : Colors.green.shade800,
                ),
              ),
            ],
          ),
          if (_item.resolutionNote != null &&
              _item.resolutionNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _item.resolutionNote!,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
          if (_item.resolvedBy != null || _item.resolvedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (_item.resolvedBy != null) ...[
                  Text(
                    'Resolved by: ${_item.resolvedBy!.name}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const Spacer(),
                if (_item.resolvedAt != null) ...[
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(_item.resolvedAt!),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.attach_file, size: 18),
            const SizedBox(width: 6),
            Text(
              'Attachments (${_item.attachments.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._item.attachments.map(
          (url) => _buildAttachmentItem(context, url, isDark),
        ),
      ],
    );
  }

  Widget _buildDiscussionThread(
    bool isDark,
    ThemeData theme,
    String? currentUserId,
  ) {
    final comments = _item.comments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.forum_outlined,
                  size: 16, color: theme.primaryColor),
            ),
            const SizedBox(width: 8),
            Text(
              'Discussion Thread (${comments.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (comments.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E232E) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 36,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No responses yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use the comment bar below to reply to this thread.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ...comments.map(
            (c) => _buildCommentItem(c, isDark, theme, currentUserId),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentItem(
    RequestComplaintComment comment,
    bool isDark,
    ThemeData theme,
    String? currentUserId,
  ) {
    final isMe = (currentUserId != null &&
        (comment.senderId == currentUserId ||
            comment.sender?.id == currentUserId));
    final senderName = comment.sender?.name ??
        (isMe ? 'You' : (comment.senderId ?? 'User'));
    final senderRole = comment.sender?.role ?? 'Member';
    final senderAvatar = comment.sender?.avatar;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: (senderAvatar != null && senderAvatar.isNotEmpty)
                  ? CachedNetworkImageProvider(senderAvatar)
                  : null,
              child: (senderAvatar == null || senderAvatar.isEmpty)
                  ? Text(
                      senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.primaryColor.withAlpha(isDark ? 50 : 25)
                    : (isDark ? const Color(0xFF1E232E) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 2),
                  bottomRight: Radius.circular(isMe ? 2 : 14),
                ),
                border: Border.all(
                  color: isMe
                      ? theme.primaryColor.withAlpha(60)
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Author & Time header
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMe ? 'You' : senderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          senderRole.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (comment.createdAt != null)
                        Text(
                          DateFormat('hh:mm a').format(comment.createdAt!),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Message Text
                  SelectableText(
                    comment.message,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),

                  // Attachments inside comment
                  if (comment.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...comment.attachments.map(
                      (url) => _buildAttachmentItem(context, url, isDark),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor.withAlpha(30),
              backgroundImage: (senderAvatar != null && senderAvatar.isNotEmpty)
                  ? CachedNetworkImageProvider(senderAvatar)
                  : null,
              child: (senderAvatar == null || senderAvatar.isEmpty)
                  ? Text(
                      'Me',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentInputBar(
    bool isDark,
    ThemeData theme,
    RequestComplaintProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pending Attachments Chips
            if (_pendingAttachments.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: _pendingAttachments.map((url) {
                    final name = url.split('/').last;
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attachment,
                              size: 14, color: theme.primaryColor),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _pendingAttachments.remove(url);
                              });
                            },
                            child: const Icon(Icons.close, size: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            if (_isUploadingAttachment) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Uploading attachment...',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],

            // Input Row
            Row(
              children: [
                // Attach file/photo popup
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'file') _pickAttachmentFile();
                    if (val == 'photo') _pickAttachmentImage();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'file',
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, size: 18),
                          SizedBox(width: 8),
                          Text('Attach Document'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'photo',
                      child: Row(
                        children: [
                          Icon(Icons.photo_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Attach Photo'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28303F) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.attach_file,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Text Input
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(),
                    decoration: InputDecoration(
                      hintText: 'Write a response...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF28303F) : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send Button
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: provider.isAddingComment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            size: 18,
                            color: Colors.white,
                          ),
                    onPressed: provider.isAddingComment ? null : _sendComment,
                  ),
                ),
              ],
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
