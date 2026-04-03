import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../admin/providers/notice_provider.dart';
import '../../auth/providers/auth_provider.dart';

class StudentNoticeScreen extends StatefulWidget {
  final bool isFromDrawer;
  const StudentNoticeScreen({super.key, required this.isFromDrawer});

  @override
  State<StudentNoticeScreen> createState() => _StudentNoticeScreenState();
}

class _StudentNoticeScreenState extends State<StudentNoticeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<NoticesNotifier>().fetchNoticesFromAPI();
    });
  }

  @override
  Widget build(BuildContext context) {
    final noticeNotifier = context.watch<NoticesNotifier>();
    final currentUser = context.watch<AuthNotifier>().user;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final notices = noticeNotifier.notices
        .where((n) => n.classId == null || n.classId == currentUser.classId)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.isFromDrawer
          ? AppBar(
              title: const Text('School Notices'),
              backgroundColor: Colors.indigo[800],
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => context.read<NoticesNotifier>().fetchNoticesFromAPI(),
        child: noticeNotifier.isLoading && notices.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : notices.isEmpty
                ? _buildEmptyState()
                : _buildNoticesList(notices),
      ),
    );
  }

  Widget _buildNoticesList(List notices) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notices.length,
      itemBuilder: (context, index) {
        final notice = notices[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: notice.isImportant
                ? Border.all(color: Colors.red.withOpacity(0.3), width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (notice.isImportant ? Colors.red : Colors.indigo).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notice.isImportant ? Icons.priority_high_rounded : Icons.notifications_rounded,
                        color: notice.isImportant ? Colors.red : Colors.indigo[800],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: notice.isImportant ? Colors.red[800] : Colors.black87,
                            ),
                          ),
                          if (notice.postedBy != null)
                            Text(
                              'By ${notice.postedBy}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    if (notice.isImportant)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  notice.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Just now', // Ideally format createdAt from notice
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.indigo.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text(
            'Keep an eye out!',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const Text(
            'New notices will appear here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

