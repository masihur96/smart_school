import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/school_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/notice_provider.dart';
import '../providers/student_provider.dart';
import '../providers/teacher_provider.dart';

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
        context.read<NoticesNotifier>().fetchNoticesFromAPI();
      }
      context.read<TeachersNotifier>().fetchTeachers();
      context.read<StudentsNotifier>().fetchStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final noticesNotifier = context.watch<NoticesNotifier>();
    final notices = noticesNotifier.notices;

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context)!.schoolNotices),
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
                        context.read<NoticesNotifier>().fetchNoticesFromAPI();
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
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
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
        label: Text(AppLocalizations.of(context)!.newNotice, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // ───────────────────────────── VIEW ──────────────────────────────────────
  void _viewNoticeDialog(BuildContext context, Notice notice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              notice.isImportant ? Icons.priority_high : Icons.campaign,
              color: notice.isImportant ? Colors.red : Colors.purple,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notice.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow(
              Icons.group_outlined,
              'Audience',
              notice.targetAudience ?? 'All',
            ),
            const SizedBox(height: 6),
            _infoRow(Icons.person_outline, 'Posted by', notice.postedBy ?? '—'),
            if (notice.isImportant) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.warning_amber_rounded, 'Priority', 'Important'),
            ],
            if (notice.avatar != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(notice.avatar!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                icon: const Icon(Icons.attach_file, size: 16),
                label: Column(
                  children: [
                    const Text('View Attachment'),
                    ],
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  foregroundColor: Colors.purple,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],

          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
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
      onSubmit: (notice, file) async {
        List<String> receiverUuids = [];
        final audience = notice.targetAudience ?? 'All';

        final teacherIds =
            context
                .read<TeachersNotifier>()
                .teachers
                .map((t) => t.userId)
                .where((id) => id.isNotEmpty)
                .toList();
        final studentIds =
            context
                .read<StudentsNotifier>()
                .students
                .map((s) => s.userId)
                .where((id) => id.isNotEmpty)
                .toList();

        if (audience == 'Students') {
          receiverUuids = studentIds;
        } else if (audience == 'Teachers') {
          receiverUuids = teacherIds;
        } else if (audience == 'All') {
          receiverUuids = [...teacherIds, ...studentIds];
        }

        await context.read<NoticesNotifier>().addNoticeToAPI(
          notice,
          receiverUuids: receiverUuids,
          noticeFile: file,
        );
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
      onSubmit: (updated, file) async {
        await context.read<NoticesNotifier>().updateNoticeOnAPI(
          updated.copyWith(id: notice.id),
          noticeFile: file,
        );
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
    required Future<void> Function(Notice, File?) onSubmit,
    required String submitLabel,
  }) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(
      text: existing?.content ?? '',
    );
    final postedByController = TextEditingController(text: initialPostedBy);
    String selectedAudience = existing?.targetAudience ?? 'Students';
    bool isImportant = existing?.isImportant ?? false;
    File? attachedFile;
    String? attachedFileName =
        existing?.fileUrl != null ? 'Existing Attachment' : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  submitLabel == 'Update' ? Icons.edit : Icons.campaign,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                submitLabel == 'Update' ? 'Edit Notice' : 'Post New Notice',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                      prefixIcon: const Icon(Icons.group, color: Colors.purple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    value: selectedAudience,
                    items: [
                      DropdownMenuItem(value: 'All', child: Text(AppLocalizations.of(context)!.all)),
                      DropdownMenuItem(
                        value: 'Students',
                        child: Text(AppLocalizations.of(context)!.studentsAudience),
                      ),
                      DropdownMenuItem(
                        value: 'Teachers',
                        child: Text(AppLocalizations.of(context)!.teachersAudience),
                      ),
                      DropdownMenuItem(
                        value: 'Parents',
                        child: Text(AppLocalizations.of(context)!.parentsAudience),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => selectedAudience = val ?? 'All'),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!.markAsImportant),
                    secondary: Icon(
                      Icons.priority_high,
                      color: isImportant ? Colors.red : Colors.grey,
                    ),
                    value: isImportant,
                    activeColor: Colors.red,
                    onChanged: (val) =>
                        setState(() => isImportant = val ?? false),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
            
                        final result = await FilePicker.pickFiles();
                        if (result != null && result.files.single.path != null) {
                          setState(() {
                            attachedFile = File(result.files.single.path!);
                            attachedFileName = result.files.single.name;
                          });
                        }

                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            color:
                                attachedFileName != null
                                    ? Colors.purple
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              attachedFileName ?? 'Attach File/Image',
                              style: TextStyle(
                                color:
                                    attachedFileName != null
                                        ? Colors.purple
                                        : Colors.grey.shade600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (attachedFileName != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  attachedFile = null;
                                  attachedFileName = null;
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon:
                  context.watch<NoticesNotifier>().isLoading
                      ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(
                        submitLabel == 'Update' ? Icons.save : Icons.send,
                        size: 18,
                      ),
              label: Text(submitLabel),
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.titleAndContentRequired),
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
                  await onSubmit(notice, attachedFile);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          submitLabel == 'Update'
                              ? 'Notice updated successfully'
                              : 'Notice posted successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.errorLabel(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.red),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.deleteNotice),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.delete, size: 18),
            label: Text(AppLocalizations.of(context)!.delete),
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (notice.id != null) {
                  await context.read<NoticesNotifier>().deleteNoticeOnAPI(
                    notice.id!,
                  );
                } else {
                  context.read<NoticesNotifier>().removeNotice('');
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.noticeDeleted),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.errorLabel(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
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
    return Card(
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
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isImportant)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.red.shade300),
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
                        style: TextStyle(fontSize: 13, height: 1.4),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'view') onView();
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.remove_red_eye_outlined,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.view),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  },
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
                if (notice.postedBy != null && notice.postedBy!.isNotEmpty)
                  _tag(
                    icon: Icons.person_outline,
                    label: notice.postedBy!,
                    color: Colors.green,
                  ),
                const Spacer(),
                if (notice.avatar != null)
                  const Icon(
                    Icons.attach_file,
                    size: 16,
                    color: Colors.purple,
                  ),

                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
