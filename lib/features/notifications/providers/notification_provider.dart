import 'package:flutter/material.dart';
import 'package:smart_school/models/notification_model.dart';
import 'package:smart_school/services/notification_service.dart';

class NotificationNotifier extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications();
      // Sort by createdAt descending
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendTest(String userId, String title, String body) async {
    try {
      await _notificationService.sendTestNotification(
        userId: userId,
        title: title,
        body: body,
      );
      // Optionally refresh list after sending test
      await fetchNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendNotification({
    required String receiverUuid,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
    String? image,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notificationService.sendNotification(
        receiverUuid: receiverUuid,
        title: title,
        message: message,
        additionalData: additionalData,
        image: image,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    // Optimistically update UI immediately
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    // Call backend to persist the change
    final success = await _notificationService.markAsRead(id);
    if (!success) {
      // Revert if the API call failed
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final unreadIndices = <int>[];
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        unreadIndices.add(i);
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }

    if (unreadIndices.isEmpty) return;
    notifyListeners();

    // Call backend to persist changes concurrently
    final results = await Future.wait(
      unreadIndices.map(
        (index) => _notificationService.markAsRead(_notifications[index].id),
      ),
    );

    bool hasError = false;
    for (int i = 0; i < results.length; i++) {
      if (!results[i]) {
        hasError = true;
        // Revert failed ones
        final index = unreadIndices[i];
        _notifications[index] = _notifications[index].copyWith(isRead: false);
      }
    }

    if (hasError) {
      notifyListeners();
    }
  }
}
