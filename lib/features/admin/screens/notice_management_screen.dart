import 'package:provider/provider.dart';
import 'package:smart_school/services/database_service.dart';
import '../providers/notice_provider.dart';
import '../../../models/school_models.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

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
      appBar: hideAppBar ? null : AppBar(
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
              : classes.firstWhere((c) => c.id == notice.classId, orElse: () => ClassRoom(id: '', name: 'Unknown')).name;
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(notice.isImportant ? Icons.priority_high : Icons.announcement, 
                           color: notice.isImportant ? Colors.red : Colors.blue),
              title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notice.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Target: $target | ${DateFormat('MMM d, yyyy').format(notice.date)}', 
                       style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => context.read<NoticesNotifier>().removeNotice(notice.id),
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
    final classes = context.read<DatabaseService>().classes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Post New Notice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Target Audience'),
                  value: selectedClass,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Global (All Classes)')),
                    ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (val) => setState(() => selectedClass = val),
                ),
                CheckboxListTile(
                  title: const Text('Mark as Important'),
                  value: isImportant,
                  onChanged: (val) => setState(() => isImportant = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  context.read<NoticesNotifier>().addNotice(Notice(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    content: contentController.text,
                    classId: selectedClass,
                    isImportant: isImportant,
                    date: DateTime.now(),
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
