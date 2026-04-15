import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      log('User granted provisional permission');
    } else {
      log('User declined or has not accepted permission');
    }

    // Get the token for this device
    String? token = await _fcm.getToken();
    log("FCM Token: $token");

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

  // Helper to trigger a notification (pseudo-implementation)
  // In a real app, this should be a call to your backend.
  Future<void> triggerNotification({
    required String title,
    required String body,
    required String topic,
    Map<String, dynamic>? data,
  }) async {
    log('Triggering notification: $title, Topic: $topic');
    // Here you would call your backend API which then sends the FCM message.
    // Example:
    /*
    await http.post(
      Uri.parse('https://your-backend.com/send-notification'),
      body: jsonEncode({
        'title': title,
        'body': body,
        'topic': topic,
        'data': data,
      }),
    );
    */
  }
}

// Background message handler must be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("Handling a background message: ${message.messageId}");
}
