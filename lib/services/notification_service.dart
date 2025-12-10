import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Background message handler (harus top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 Background message received: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔔 Initializing Notification Service...');

      // 1. Request permission
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('⚠️ Notification permission not granted');
        _isInitialized = true; // Mark as initialized to prevent retry loops
        return;
      }

      // 2. Initialize local notifications
      await _initializeLocalNotifications();

      // 3. Get FCM token
      await _getFCMToken();

      // 4. Setup message handlers
      _setupMessageHandlers();

      // 5. Subscribe to topics (optional)
      await _subscribeToTopics();

      _isInitialized = true;
      print('✅ Notification Service initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Notification Service initialization failed: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = true; // Mark as initialized to prevent app crash
    }
  }

  /// Request notification permission
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📋 Permission status: ${settings.authorizationStatus}');
    return settings;
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('✅ Local notifications initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');
      });
    } catch (e) {
      print('⚠️ Failed to get FCM token: $e');
      print('⚠️ This device may not have Google Play Services installed');
      print('⚠️ Continuing without push notifications...');
      // Don't rethrow - app should still work without FCM
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    try {
      // 1. Foreground messages (app is open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📬 Foreground message received');
        print('   Title: ${message.notification?.title}');
        print('   Body: ${message.notification?.body}');
        print('   Data: ${message.data}');
        _showLocalNotification(message);
      });

      // 2. Background/Terminated messages (user taps notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🚀 Message opened app from background');
        print('   Data: ${message.data}');
        _handleNotificationTap(message);
      });

      // 3. Check if app was opened from terminated state
      _firebaseMessaging
          .getInitialMessage()
          .then((RemoteMessage? message) {
            if (message != null) {
              print('🚀 App opened from terminated state');
              print('   Data: ${message.data}');
              _handleNotificationTap(message);
            }
          })
          .catchError((e) {
            print('⚠️ Error checking initial message: $e');
          });
    } catch (e) {
      print('⚠️ Error setting up message handlers: $e');
      // Don't rethrow - this is optional functionality
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'splitify_channel',
      'Splitify Notifications',
      channelDescription: 'Notifications for Splitify app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF3B5BFF),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    print('🔔 Handling notification tap with data: $data');

    final type = data['type'] as String?;
    switch (type) {
      case 'friend_request':
        print('Navigate to friend requests');
        break;
      case 'activity_invitation':
        final activityId = data['activityId'];
        print('Navigate to activity: $activityId');
        break;
      case 'payment_reminder':
        print('Navigate to payment');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  /// Subscribe to topics
  Future<void> _subscribeToTopics() async {
    try {
      await _firebaseMessaging.subscribeToTopic('all_users');
      print('✅ Subscribed to topic: all_users');
    } catch (e) {
      print('❌ Failed to subscribe to topics: $e');
    }
  }

  /// Unsubscribe from topics
  Future<void> unsubscribeFromTopics() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('all_users');
      print('✅ Unsubscribed from topic: all_users');
    } catch (e) {
      print('❌ Failed to unsubscribe: $e');
    }
  }

  /// Show test notification (for debugging)
  Future<void> showTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notifications for debugging',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      'Test Notification',
      'This is a test notification from Splitify!',
      details,
    );
  }

  /// Show receipt OCR completion notification
  Future<void> showReceiptOCRCompleteNotification(int itemCount) async {
    try {
      // Check if initialized and permission granted
      if (!_isInitialized) {
        print('⚠️ NotificationService not initialized, skipping notification');
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        'receipt_channel',
        'Receipt OCR',
        channelDescription: 'Notifications for receipt OCR completion',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      final details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        1, // Unique ID for receipt notifications
        '✅ Receipt OCR Complete',
        '$itemCount items extracted! Ready to review.',
        details,
      );
    } catch (e) {
      print('❌ Failed to show notification: $e');
      // Don't rethrow - we don't want to crash the app if notification fails
    }
  }
}
