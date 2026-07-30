import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/notifications/providers/notification_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  final Color color;
  const NotificationScreen({super.key, required this.color});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationNotifier>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.color,

        title: Text(AppLocalizations.of(context)!.notificationsTitle),
        foregroundColor: AppColors.white,

        leading: BackButton(),

      ),
      body: Consumer<NotificationNotifier>(
        builder: (context, notifier, child) {
          if (notifier.isLoading) {
            return _NotificationShimmer(isDark: isDark);
          }

          if (notifier.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.errorLabel(notifier.error ?? '')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => notifier.fetchNotifications(),
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          if (notifier.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notifier.fetchNotifications(),
            child: ListView.builder(
              itemCount: notifier.notifications.length,
              itemBuilder: (context, index) {
                final notification = notifier.notifications[index];

                return _NotificationItem(notification: notification);
              },
            ),
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     final auth = context.read<AuthNotifier>();
      //     final user = auth.user;
      //     if (user != null) {
      //       context.read<NotificationNotifier>().sendTest(
      //         user.id,
      //         "Test Notification",
      //         "This is a test notification from the app",
      //       );
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(content: Text('Test notification sent!')),
      //       );
      //     }
      //   },
      //   child: const Icon(Icons.send),
      //   tooltip: 'Send Test Notification',
      // ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d, y').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
      return Card(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      color: notification.isRead ? null : Colors.blue.withOpacity(0.05),
      child: ListTile(
        leading: Column(
          children: [
            CircleAvatar(
              backgroundColor: notification.isRead
                  ? Colors.grey[200]
                  : Colors.blue[100],
              child: Icon(
                Icons.notifications,
                color: notification.isRead
                    ? Colors.grey[600]
                    : Colors.blue[700],
              ),
            ),
            Spacer(),
            if (!notification.isRead)
              CircleAvatar(radius: 5, backgroundColor: Colors.blue),
          ],
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          // Handle notification tap
          context.read<NotificationNotifier>().markAsRead(notification.id);

          if (notification.data != null && notification.data!.isNotEmpty) {
            _showDataDialog(context, notification);
          }
        },
      ),
    );
  }

  void _showDataDialog(
    BuildContext context,
    NotificationModel notificationModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.notificationDetails),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                notificationModel.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(notificationModel.body),
            ],
          ),
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
}

// ─── Shimmer skeleton ────────────────────────────────────────────────────────

class _NotificationShimmer extends StatelessWidget {
  final bool isDark;
  const _NotificationShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (context, _) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar placeholder
                  const CircleAvatar(radius: 24, backgroundColor: Colors.white),
                  const SizedBox(width: 14),
                  // Text column placeholder
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title line
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Body line 1
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Body line 2 (shorter)
                        Container(
                          height: 12,
                          width: MediaQuery.of(context).size.width * 0.45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Timestamp pill
                        Container(
                          height: 10,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
