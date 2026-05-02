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

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      // Logic to mark as read locally
      // In a real app, you'd also call the backend
      notifyListeners();
    }
  }
}
