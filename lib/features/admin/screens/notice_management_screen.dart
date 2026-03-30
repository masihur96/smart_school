import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/school_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/notice_provider.dart';

class NoticeManagementScreen extends StatefulWidget {
  final bool hideAppBar;
  const NoticeManagementScreen({super.key, this.hideAppBar = false});

  @override
  State<NoticeManagementScreen> createState() => _NoticeManagementScreenState();
}

class _NoticeManagementScreenState extends State<NoticeManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch real notices from API so every item has a server id
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      if (user?.schoolId != null) {
        context
            .read<NoticesNotifier>()
            .fetchNoticesFromAPI(user!.schoolId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final noticesNotifier = context.watch<NoticesNotifier>();
    final notices = noticesNotifier.notices;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('School Notices'),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              actions: [
                if (noticesNotifier.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: () {
                      final user = context.read<AuthNotifier>().user;
                      if (user?.schoolId != null) {
                        context
                            .read<NoticesNotifier>()
                            .fetchNoticesFromAPI(user!.schoolId!);
                      }
                    },
                  ),
              ],
            ),
      body: noticesNotifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notices.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No notices posted yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    return _NoticeCard(
                      notice: notice,
                      onView: () => _viewNoticeDialog(context, notice),
                      onEdit: () => _editNoticeDialog(context, notice),
                      onDelete: () => _confirmDelete(context, notice),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNoticeDialog(context),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('New Notice', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ───────────────────────────── VIEW ──────────────────────────────────────
  void _viewNoticeDialog(BuildContext context, Notice notice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              notice.isImportant ? Icons.priority_high : Icons.campaign,
              color: notice.isImportant ? Colors.red : Colors.purple,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(notice.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notice.content,
                style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow(Icons.group_outlined, 'Audience',
                notice.targetAudience ?? 'All'),
            const SizedBox(height: 6),
            _infoRow(Icons.person_outline, 'Posted by',
                notice.postedBy ?? '—'),
            if (notice.isImportant) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.warning_amber_rounded, 'Priority',
                  'Important',
                  color: Colors.red),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color color = Colors.purple}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  // ──────────────────────────── ADD ────────────────────────────────────────
  void _addNoticeDialog(BuildContext context) {
    final user = context.read<AuthNotifier>().user;
    _showNoticeForm(
      context,
      initialPostedBy: user?.name ?? '',
      schoolId: user?.schoolId ?? '',
      onSubmit: (notice) async {
        await context.read<NoticesNotifier>().addNoticeToAPI(notice);
      },
      submitLabel: 'Post',
    );
  }

  // ──────────────────────────── EDIT ───────────────────────────────────────
  void _editNoticeDialog(BuildContext context, Notice notice) {
    final user = context.read<AuthNotifier>().user;
    _showNoticeForm(
      context,
      existing: notice,
      initialPostedBy: notice.postedBy ?? user?.name ?? '',
      schoolId: notice.schoolId ?? user?.schoolId ?? '',
      onSubmit: (updated) async {
        await context
            .read<NoticesNotifier>()
            .updateNoticeOnAPI(updated.copyWith(id: notice.id));
      },
      submitLabel: 'Update',
    );
  }

  // ─────────────────────── SHARED FORM ─────────────────────────────────────
  void _showNoticeForm(
    BuildContext context, {
    Notice? existing,
    required String initialPostedBy,
    required String schoolId,
    required Future<void> Function(Notice) onSubmit,
    required String submitLabel,
  }) {
    final titleController =
        TextEditingController(text: existing?.title ?? '');
    final contentController =
        TextEditingController(text: existing?.content ?? '');
    final postedByController =
        TextEditingController(text: initialPostedBy);
    String selectedAudience = existing?.targetAudience ?? 'Students';
    bool isImportant = existing?.isImportant ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  submitLabel == 'Update'
                      ? Icons.edit
                      : Icons.campaign,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                submitLabel == 'Update'
                    ? 'Edit Notice'
                    : 'Post New Notice',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField(
                    controller: titleController,
                    label: 'Title',
                    hint: 'e.g. Welcome Back!',
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: contentController,
                    label: 'Content',
                    hint: 'e.g. School reopens next Monday.',
                    icon: Icons.notes,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: postedByController,
                    label: 'Posted By',
                    hint: 'e.g. Principal',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Target Audience',
                      prefixIcon: const Icon(Icons.group,
                          color: Colors.purple),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    value: selectedAudience,
                    items: const [
                      DropdownMenuItem(
                          value: 'All', child: Text('All')),
                      DropdownMenuItem(
                          value: 'Students', child: Text('Students')),
                      DropdownMenuItem(
                          value: 'Teachers', child: Text('Teachers')),
                      DropdownMenuItem(
                          value: 'Parents', child: Text('Parents')),
                    ],
                    onChanged: (val) =>
                        setState(() => selectedAudience = val ?? 'All'),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark as Important'),
                    secondary: Icon(
                      Icons.priority_high,
                      color: isImportant ? Colors.red : Colors.grey,
                    ),
                    value: isImportant,
                    activeColor: Colors.red,
                    onChanged: (val) =>
                        setState(() => isImportant = val ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: context.watch<NoticesNotifier>().isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(
                      submitLabel == 'Update'
                          ? Icons.save
                          : Icons.send,
                      size: 18),
              label: Text(submitLabel),
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Title and content are required.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                final notice = Notice(
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  targetAudience: selectedAudience,
                  isImportant: isImportant,
                  schoolId: schoolId,
                  postedBy: postedByController.text.trim(),
                );
                try {
                  await onSubmit(notice);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(submitLabel == 'Update'
                          ? 'Notice updated successfully'
                          : 'Notice posted successfully'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── DELETE ──────────────────────────────────────
  void _confirmDelete(BuildContext context, Notice notice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Notice'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${notice.title}"?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (notice.id != null) {
                  await context
                      .read<NoticesNotifier>()
                      .deleteNoticeOnAPI(notice.id!);
                } else {
                  context
                      .read<NoticesNotifier>()
                      .removeNotice('');
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notice deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.purple),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────── NOTICE CARD ─────────────────────────────────
class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoticeCard({
    required this.notice,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isImportant = notice.isImportant;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isImportant
            ? Border.all(color: Colors.red.shade300, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isImportant
                        ? Colors.red.withOpacity(0.1)
                        : Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isImportant ? Icons.priority_high : Icons.campaign,
                    color: isImportant ? Colors.red : Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ),
                          if (isImportant)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.red.shade300),
                              ),
                              child: const Text(
                                'Important',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notice.content,
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 3-dot menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'view') onView();
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(children: [
                        Icon(Icons.remove_red_eye_outlined,
                            size: 18, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('View'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: Colors.orange),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                _tag(
                  icon: Icons.group_outlined,
                  label: notice.targetAudience ?? 'All',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                if (notice.postedBy != null &&
                    notice.postedBy!.isNotEmpty)
                  _tag(
                    icon: Icons.person_outline,
                    label: notice.postedBy!,
                    color: Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(
      {required IconData icon,
      required String label,
      required Color color}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
