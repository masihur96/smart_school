import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/models/notification_model.dart';
import 'package:smart_school/models/user_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permissions for iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log('User granted provisional permission');
    } else {
      log('User declined or has not accepted permission');
    }

    // Get the token for this device
    String? token = await _fcm.getToken();
    log("FCM Token: $token");

    if (token != null) {
      await registerToken(token);
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }

      // Handle the JSON body here if needed
      _handleMessage(message);
    });

    // Handle when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('A new onMessageOpenedApp event was published!');
      _handleMessage(message);
    });
  }

  Future<void> registerToken(String fcmToken) async {
    try {
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        log('No auth token found, skipping token registration');
        return;
      }

      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.registerFcmToken,
        data: {
          'token': fcmToken,
          'deviceType': deviceType,
        },
        header: {'Authorization': 'Bearer $authToken'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        log('FCM Token registered successfully');
      } else {
        log('Failed to register FCM Token: ${response?.data}');
      }
    } catch (e) {
      log('Error registering FCM token: $e');
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final authToken = await StorageService.getToken();
      if (authToken == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.notifications,
        header: {'Authorization': 'Bearer $authToken'},
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['data'] is List) {
          return NotificationModel.fromList(data['data']);
        } else if (data is List) {
          return NotificationModel.fromList(data);
        }
      }
      return [];
    } catch (e) {
      log('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> sendTestNotification({
    required String userId,
    required String title,
    required String body,
    String topic = "all_users",
    Map<String, dynamic>? data,
  }) async {
    try {
      final authToken = await StorageService.getToken();
      if (authToken == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.sendTestNotification,
        data: {
          "title": title,
          "body": body,
          "topic": topic,
          "userId": userId,
          "data": data ?? {}
        },
        header: {'Authorization': 'Bearer $authToken'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        log('Test notification sent successfully');
      } else {
        log('Failed to send test notification: ${response?.data}');
      }
    } catch (e) {
      log('Error sending test notification: $e');
    }
  }

  Future<void> sendNotification({
    required String receiverUuid,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
    String? image,
  }) async {
    try {
      final authToken = await StorageService.getToken();
      if (authToken == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.sendNotification,
        data: {
          "receiver_uuid": receiverUuid,
          "title": title,
          "message": message,
          "additional_data": additionalData ?? {},
          "image": image
        },
        header: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'accept': '*/*'
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('Notification sent successfully');
      } else {
        log('Failed to send notification: ${response?.data}');
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      log('Error sending notification: $e');
      rethrow;
    }
  }

  void _handleMessage(RemoteMessage message) {
    // Example of handling JSON body
    if (message.data.isNotEmpty) {
      try {
        // You can parse specific fields from message.data
        log('Handling JSON data: ${jsonEncode(message.data)}');
      } catch (e) {
        log('Error parsing message data: $e');
      }
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    log('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    log('Unsubscribed from topic: $topic');
  }

  // Legacy method to fix breaking change.
  // Ideally, this should be updated to a specific backend endpoint for different notification types.
  Future<void> triggerNotification({
    required String title,
    required String body,
    required String topic,
    Map<String, dynamic>? data,
  }) async {
    // For now, we'll use the sendTestNotification logic.
    // We'll use a placeholder userId if not provided in data, or try to get it from data.
    final userId = data?['userId'] ?? "all_users_placeholder";
    await sendTestNotification(
      userId: userId,
      title: title,
      body: body,
      topic: topic,
      data: data,
    );
  }

  Future<void> subscribeToUserTopics(User user) async {
    try {
      // General topic
      await subscribeToTopic('all');

      // Role-specific ID topics
      if (user.role == UserRole.superadmin || user.role == UserRole.admin) {
        await subscribeToTopic('admin_${user.id}');
      } else if (user.role == UserRole.teacher) {
        await subscribeToTopic('teacher_${user.id}');
      } else if (user.role == UserRole.student) {
        await subscribeToTopic('student_${user.id}');
      }

      // Legacy ID support (keep for compatibility if needed, or remove if strictly following new structure)
      await subscribeToTopic(user.id);

      // School specific topic
      if (user.schoolId != null && user.schoolId!.isNotEmpty) {
        await subscribeToTopic('school_${user.schoolId}');
      }

      // Class specific topic
      if (user.classId != null && user.classId!.isNotEmpty) {
        await subscribeToTopic('class_${user.classId}');
      }

      // Section specific topic
      if (user.sectionId != null && user.sectionId!.isNotEmpty) {
        await subscribeToTopic('section_${user.sectionId}');
      }

      // Functional topics based on role
      if (user.role == UserRole.superadmin) {
        await subscribeToTopic('subscription');
      }

      if (user.role == UserRole.admin) {
        await subscribeToTopic('notice');
        await subscribeToTopic('exam');
        await subscribeToTopic('routine');
        await subscribeToTopic('result');
        await subscribeToTopic('homework');
        await subscribeToTopic('attendance');
      }

      if (user.role == UserRole.teacher) {
        await subscribeToTopic('notice');
        await subscribeToTopic('routine');
        await subscribeToTopic('exam');
      }

      if (user.role == UserRole.student) {
        await subscribeToTopic('notice');
        await subscribeToTopic('routine');
        await subscribeToTopic('exam');
        await subscribeToTopic('result');
        await subscribeToTopic('homework');
        await subscribeToTopic('attendance');
      }

      log('Successfully subscribed to all user topics for ${user.name} (${user.role.name})');
    } catch (e) {
      log('Error subscribing to user topics: $e');
    }
  }

  Future<void> unsubscribeFromUserTopics(User user) async {
    try {
      await unsubscribeFromTopic('all');

      if (user.role == UserRole.superadmin || user.role == UserRole.admin) {
        await unsubscribeFromTopic('admin_${user.id}');
      } else if (user.role == UserRole.teacher) {
        await unsubscribeFromTopic('teacher_${user.id}');
      } else if (user.role == UserRole.student) {
        await unsubscribeFromTopic('student_${user.id}');
      }

      await unsubscribeFromTopic(user.id);

      if (user.schoolId != null && user.schoolId!.isNotEmpty) {
        await unsubscribeFromTopic('school_${user.schoolId}');
      }

      if (user.classId != null && user.classId!.isNotEmpty) {
        await unsubscribeFromTopic('class_${user.classId}');
      }

      if (user.sectionId != null && user.sectionId!.isNotEmpty) {
        await unsubscribeFromTopic('section_${user.sectionId}');
      }

      // Functional topics
      if (user.role == UserRole.superadmin) {
        await unsubscribeFromTopic('subscription');
      }

      if (user.role == UserRole.admin) {
        await unsubscribeFromTopic('notice');
        await unsubscribeFromTopic('exam');
        await unsubscribeFromTopic('routine');
        await unsubscribeFromTopic('result');
        await unsubscribeFromTopic('homework');
        await unsubscribeFromTopic('attendance');
      }

      if (user.role == UserRole.teacher) {
        await unsubscribeFromTopic('notice');
        await unsubscribeFromTopic('routine');
        await unsubscribeFromTopic('exam');
      }

      if (user.role == UserRole.student) {
        await unsubscribeFromTopic('notice');
        await unsubscribeFromTopic('routine');
        await unsubscribeFromTopic('exam');
        await unsubscribeFromTopic('result');
        await unsubscribeFromTopic('homework');
        await unsubscribeFromTopic('attendance');
      }

      log('Successfully unsubscribed from all user topics for ${user.name}');
    } catch (e) {
      log('Error unsubscribing from user topics: $e');
    }
  }
}

// Background message handler must be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("Handling a background message: ${message.messageId}");
}
