import re

with open('lib/features/student/screens/student_dashboard_screen.dart', 'r') as f:
    content = f.read()

# 1. replace imports
import_insert = """import 'package:smart_school/features/ai_tutor/screen/ai_tutor_chat_screen.dart';
import 'package:smart_school/features/library/providers/library_book_provider.dart';
import 'package:smart_school/features/library/screens/book_detail_screen.dart';
import 'package:smart_school/features/library/screens/library_dashboard_screen.dart';
import 'package:smart_school/features/library/widgets/book_grid_card.dart';
import 'package:smart_school/features/online_class/presentation/screens/online_class_list_screen.dart';
import 'package:smart_school/features/online_class/providers/online_class_provider.dart';
import 'package:smart_school/features/student/screens/student_notice_screen.dart';
import 'package:smart_school/models/online_class_model.dart';
import 'package:url_launcher/url_launcher.dart';"""

content = content.replace("import 'package:smart_school/features/ai_tutor/screen/ai_tutor_chat_screen.dart';", import_insert)

# 2. replace initState body
init_state_old = """      if (mounted) {
        final notifProvider = context.read<NotificationNotifier>();
        if (notifProvider.notifications.isEmpty) {
          notifProvider.fetchNotifications();
        }
      }"""

init_state_new = """      if (mounted) {
        final notifProvider = context.read<NotificationNotifier>();
        if (notifProvider.notifications.isEmpty) {
          notifProvider.fetchNotifications();
        }

        final onlineClassProvider = context.read<OnlineClassProvider>();
        if (onlineClassProvider.onlineClasses.isEmpty) {
          onlineClassProvider.fetchOnlineClasses();
        }

        final libraryProvider = context.read<LibraryBookNotifier>();
        if (libraryProvider.books.isEmpty) {
          libraryProvider.fetchBooks();
        }
      }"""

content = content.replace(init_state_old, init_state_new)

# 3. replace _buildDashboardOverview

build_dash_old = """  Widget _buildDashboardOverview(
    BuildContext context,
    User? user,
    AppLocalizations l10n,
  ) {
    final provider = context.watch<StudentDashboardProvider>();
    final data = provider.dashboardData;"""

build_dash_new = """  Widget _buildDashboardOverview(
    BuildContext context,
    User? user,
    AppLocalizations l10n,
  ) {
    final provider = context.watch<StudentDashboardProvider>();
    final onlineClassProvider = context.watch<OnlineClassProvider>();
    final libraryProvider = context.watch<LibraryBookNotifier>();

    final upcomingClasses = onlineClassProvider.onlineClasses
        .where(
          (c) => c.scheduledTime.isAfter(
            DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        )
        .toList();

    final availableBooks = libraryProvider.books
        .where((b) => b.isAvailable)
        .toList();

    final data = provider.dashboardData;"""

content = content.replace(build_dash_old, build_dash_new)

# section 1

section_old = """                  _buildAttendanceSection(context, data, l10n),
                  const SizedBox(height: 24),
                  if (data?.myRecentExamListWithResult.isNotEmpty ?? false) ...["""

section_new = """                  _buildAttendanceSection(context, data, l10n),
                  const SizedBox(height: 24),
                  if (upcomingClasses.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Online Classes',
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const OnlineClassListScreen(isAdminOrTeacher: false),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: upcomingClasses.length > 5
                            ? 5
                            : upcomingClasses.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 48,
                              child: _buildOnlineClassCard(
                                context,
                                upcomingClasses[index],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (data?.myRecentExamListWithResult.isNotEmpty ?? false) ...["""

content = content.replace(section_old, section_new)

# section 2

section2_old = """                    const SizedBox(height: 24),
                  ],
                  if (data?.myRecentNotice.isNotEmpty ?? false) ...["""

section2_new = """                    const SizedBox(height: 24),
                  ],
                  if (availableBooks.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Library Books',
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LibraryDashboardScreen(
                              comeFrom: 'student',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: availableBooks.length > 5
                            ? 5
                            : availableBooks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SizedBox(
                              width: 150,
                              child: BookGridCard(
                                book: availableBooks[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookDetailScreen(
                                        comeFrom: 'student',
                                        book: availableBooks[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (data?.myRecentNotice.isNotEmpty ?? false) ...["""

content = content.replace(section2_old, section2_new)

# notices section

notice_old = """                  if (data?.myRecentNotice.isNotEmpty ?? false) ...[
                    _buildSectionHeader(
                      l10n.notices,
                      onSeeAll: () => _tabController.animateTo(3),
                    ),
                    const SizedBox(height: 12),
                    ...data!.myRecentNotice
                        .take(3)
                        .map((notice) => _buildNoticeCard(context, notice)),
                    const SizedBox(height: 24),
                  ],"""

notice_new = """                  if (data?.myRecentNotice.isNotEmpty ?? false) ...[
                    _buildSectionHeader(
                      l10n.notices,
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const StudentNoticeScreen(isFromDrawer: true),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: data!.myRecentNotice.length > 5
                            ? 5
                            : data.myRecentNotice.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.75,
                              child: _buildNoticeCard(
                                context,
                                data.myRecentNotice[index],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],"""

content = content.replace(notice_old, notice_new)

notice_card_old = """  Widget _buildNoticeCard(BuildContext context, Notice notice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.isImportant)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.priority_high,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                Expanded(
                  child: Text(
                    notice.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  notice.targetAudience ?? '',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              notice.content,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  notice.postedBy ?? 'Admin',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }"""

notice_card_new = """  Widget _buildNoticeCard(BuildContext context, Notice notice) {
    bool isNew = false;
    String timeAgo = 'Unknown';
    if (notice.createdAt != null) {
      final diff = DateTime.now().difference(notice.createdAt!);
      isNew = diff.inDays <= 3;

      if (diff.inDays == 0) {
        if (DateTime.now().day == notice.createdAt!.day) {
          timeAgo = 'Today';
        } else {
          timeAgo = 'Yesterday';
        }
      } else if (diff.inDays == 1) {
        timeAgo = 'Yesterday';
      } else if (diff.inDays < 7) {
        timeAgo = '${diff.inDays} days ago';
      } else {
        timeAgo = DateFormat('MMM dd, yyyy').format(notice.createdAt!);
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showNoticeDetails(context, notice, timeAgo),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (notice.isImportant)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.priority_high,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      notice.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isNew)
                    Text(
                      'New',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notice.content,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.person, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    notice.postedBy ?? 'Admin',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoticeDetails(BuildContext context, Notice notice, String timeAgo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (notice.isImportant)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.priority_high, color: Colors.amber, size: 20),
              ),
            Expanded(child: Text(notice.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Posted by ${notice.postedBy ?? 'Admin'} • $timeAgo',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Text(notice.content, style: const TextStyle(fontSize: 15)),
              if (notice.fileUrl != null && notice.fileUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(notice.fileUrl!);
                    try {
                      if (!await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      )) {
                        await launchUrl(url, mode: LaunchMode.platformDefault);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open attachment'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.attachment),
                  label: const Text('View Attachment'),
                ),
              ],
            ],
          ),
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

  Widget _buildOnlineClassCard(BuildContext context, OnlineClass onlineClass) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (onlineClass.meetLink.isNotEmpty) {
            try {
              launchUrl(
                Uri.parse(onlineClass.meetLink),
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {}
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      onlineClass.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                onlineClass.description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.class_, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            onlineClass.className ?? 'Meeting',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'hh:mm a',
                          ).format(onlineClass.scheduledTime),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onlineClass.meetLink.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          try {
                            launchUrl(
                              Uri.parse(onlineClass.meetLink),
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Join',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }"""

content = content.replace(notice_card_old, notice_card_new)

with open('lib/features/student/screens/student_dashboard_screen.dart', 'w') as f:
    f.write(content)
