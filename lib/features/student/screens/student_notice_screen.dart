import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/providers/notice_provider.dart';
import '../../admin/providers/student_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/school_models.dart';
import 'package:intl/intl.dart';

class StudentNoticeScreen extends ConsumerWidget {
  const StudentNoticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final student = ref.watch(studentsProvider).firstWhere((s) => s.userId == currentUser.id);
    final notices = ref.watch(noticesProvider).where((n) => 
      n.classId == null || n.classId == student.classId
    ).toList();
    
    notices.sort((a, b) {
      if (a.isImportant && !b.isImportant) return -1;
      if (!a.isImportant && b.isImportant) return 1;
      return b.date.compareTo(a.date);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
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
                    side: notice.isImportant ? const BorderSide(color: Colors.red, width: 1) : BorderSide.none,
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: notice.isImportant ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      child: Icon(notice.isImportant ? Icons.priority_high : Icons.notifications, 
                                 color: notice.isImportant ? Colors.red : Colors.green),
                    ),
                    title: Text(notice.title, style: TextStyle(fontWeight: notice.isImportant ? FontWeight.bold : FontWeight.w600)),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(notice.date), style: const TextStyle(fontSize: 12)),
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
