import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../admin/providers/notice_provider.dart';
import '../../auth/providers/auth_provider.dart';

class StudentNoticeScreen extends StatelessWidget {
  final bool isFromDrawer;
  const StudentNoticeScreen({super.key,required this.isFromDrawer});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthNotifier>().user;
    if (currentUser == null)
      return const Scaffold(body: Center(child: Text('Not logged in')));

    final notices = context
        .watch<NoticesNotifier>()
        .notices
        .where((n) => n.classId == null || n.classId == currentUser.classId)
        .toList();

    return Scaffold(
      appBar:isFromDrawer? AppBar(
        title: const Text('Not ices'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ):null,
      body: notices.isEmpty
          ? const Center(child: Text('No notices found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final notice = notices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: notice.isImportant ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: notice.isImportant
                        ? const BorderSide(color: Colors.red, width: 1)
                        : BorderSide.none,
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: notice.isImportant
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      child: Icon(
                        notice.isImportant
                            ? Icons.priority_high
                            : Icons.notifications,
                        color: notice.isImportant ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(
                      notice.title,
                      style: TextStyle(
                        fontWeight: notice.isImportant
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                    ),

                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(notice.content),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
