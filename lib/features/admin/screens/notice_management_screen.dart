import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/services/database_service.dart';

import '../../../models/school_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/notice_provider.dart';

class NoticeManagementScreen extends StatelessWidget {
  final bool hideAppBar;
  const NoticeManagementScreen({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final noticesNotifier = context.watch<NoticesNotifier>();
    final notices = noticesNotifier.notices;
    final dbService = context.watch<DatabaseService>();
    final classes = dbService.classes;

    return Scaffold(
      appBar: hideAppBar
          ? null
          : AppBar(
              title: const Text('School Notices'),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
      body: ListView.builder(
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final notice = notices[index];
          final target = notice.classId == null
              ? 'Global'
              : classes
                    .firstWhere(
                      (c) => c.id == notice.classId,
                      orElse: () => ClassRoom(id: '', name: 'Unknown'),
                    )
                    .name;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                notice.isImportant ? Icons.priority_high : Icons.announcement,
                color: notice.isImportant ? Colors.red : Colors.blue,
              ),
              title: Text(
                notice.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target: $target',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNoticeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNoticeDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String? selectedClass;
    bool isImportant = false;
    final dbService = context.read<DatabaseService>();
    final classes = dbService.classes;
    final authNotifier = context.read<AuthNotifier>();
    final currentUser = authNotifier.user;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Post New Notice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Target Audience',
                  ),
                  value: selectedClass,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Global (All Classes)'),
                    ),
                    ...classes.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (val) => setState(() => selectedClass = val),
                ),
                CheckboxListTile(
                  title: const Text('Mark as Important'),
                  value: isImportant,
                  onChanged: (val) =>
                      setState(() => isImportant = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  final notice = Notice(
                    title: titleController.text,
                    content: contentController.text,
                    classId: selectedClass,
                    isImportant: isImportant,

                    schoolId:
                        currentUser?.schoolId ??
                        '', // Fallback to user provided default for this session
                    postedBy:
                        currentUser?.id ??
                        '', // Fallback to user provided default
                    audience: selectedClass != null
                        ? classes.firstWhere((c) => c.id == selectedClass).name
                        : 'Global',
                  );

                  try {
                    await context.read<NoticesNotifier>().addNoticeToAPI(
                      notice,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notice posted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: context.watch<NoticesNotifier>().isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
