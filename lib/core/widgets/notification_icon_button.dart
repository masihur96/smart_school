import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/route_generator.dart';
import 'package:smart_school/features/notifications/providers/notification_provider.dart';

class NotificationIconButton extends StatelessWidget {
  final Color? color;
  const NotificationIconButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined),
          color: color,
          onPressed: () {
            Navigator.pushNamed(context, RouteGenerator.notificationRoute);
          },
        ),
        Consumer<NotificationNotifier>(
          builder: (context, notifier, child) {
            if (notifier.unreadCount == 0) return const SizedBox.shrink();
            return Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '${notifier.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
