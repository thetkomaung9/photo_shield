import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Push notification service for Firebase Messaging and local notifications
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  late final FirebaseMessaging _firebaseMessaging;
  late final FlutterLocalNotificationsPlugin _localNotifications;

  /// Initialize Firebase Messaging and local notifications
  Future<void> initialize() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();

      // Request notification permission
      await _requestPermission();

      // Initialize local notifications
      await _initLocalNotifications();

      // Setup message handlers
      _setupMessageHandlers();

      // Get FCM token
      final token = await getToken();
      if (token != null) {
        // Save token to server if needed
        await _saveTokenToServer(token);
      }
    } catch (e) {
      debugLog('Error initializing push notifications: $e');
      // Continue without push notifications
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugLog('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugLog('User granted provisional notification permission');
      }
    } catch (e) {
      debugLog('Error requesting notification permission: $e');
    }
  }

  /// Initialize local notifications for both Android and iOS
  Future<void> _initLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      // Handle notification taps on iOS
      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugLog('Error initializing local notifications: $e');
    }
  }

  /// Setup message handlers for foreground, background, and terminated states
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugLog('Message clicked: ${message.messageId}');
      _handleMessageTap(message);
    });
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugLog('Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// Handle background messages (called from main.dart)
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugLog('Background message: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'photo_shield_notifications',
      'PhotoShield Notifications',
      channelDescription: 'Notifications from PhotoShield',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }

  Future<void> showLocalAlert({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'photo_shield_notifications',
      'PhotoShield Notifications',
      channelDescription: 'Notifications from PhotoShield',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      title.hashCode ^ body.hashCode,
      title,
      body,
      details,
      payload: data.isEmpty ? null : jsonEncode(data),
    );
  }

  /// Handle notification tap
  void _handleMessageTap(RemoteMessage message) {
    // TODO: Implement navigation based on message data
    // Example: navigate to detection screen if type is 'detection'
    debugLog('Handling message tap with data: ${message.data}');
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugLog('FCM Token: $token');
      return token;
    } catch (e) {
      debugLog('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugLog('Subscribed to topic: $topic');
    } catch (e) {
      debugLog('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugLog('Unsubscribed from topic: $topic');
    } catch (e) {
      debugLog('Error unsubscribing from topic: $e');
    }
  }

  /// Save FCM token to server
  Future<void> _saveTokenToServer(String token) async {
    // TODO: Implement API call to save token to backend
    debugLog('Saving FCM token to server: $token');
  }
}

/// Debug logging helper
void debugLog(String message) {
  // ignore: avoid_print
  print('[PushNotificationService] $message');
}

/// Provider
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});
