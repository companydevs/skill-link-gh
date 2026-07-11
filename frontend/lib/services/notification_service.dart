import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message: ${message.messageId}');
  debugPrint('📦 Data: ${message.data}');
  debugPrint('📬 Notification: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Navigation callback for handling notification taps
  Function(String route, Map<String, dynamic> data)? onNotificationTap;

  /// Initialize notification service
  Future<void> initialize() async {
    debugPrint('🔔 Initializing NotificationService...');

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get and save FCM token
    await _saveFCMToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ NotificationService initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('🔔 Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ User granted provisional permission');
    } else {
      debugPrint('❌ User declined notification permission');
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Chat messages channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Payments channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'payments',
        'Payments',
        description: 'Notifications for payment transactions',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Bookings channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'bookings',
        'Bookings',
        description: 'Notifications for booking updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // General channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'general',
        'General',
        description: 'General notifications',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    debugPrint('✅ Android notification channels created');
  }

  /// Get and save FCM token to Firestore
  Future<void> _saveFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('❌ Failed to get FCM token');
        return;
      }

      debugPrint('🔑 FCM Token: $token');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, token not saved');
        return;
      }

      // Save token to user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            'platform': Platform.isAndroid ? 'android' : 'ios',
          });

      debugPrint('✅ FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String token) async {
    debugPrint('🔄 FCM token refreshed: $token');
    await _saveFCMToken();
  }

  /// Handle foreground messages (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Foreground message received');
    debugPrint('📬 Title: ${message.notification?.title}');
    debugPrint('📝 Body: ${message.notification?.body}');
    debugPrint('📦 Data: ${message.data}');

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final type = data['type'] ?? 'general';

    // Determine channel and priority based on type
    String channelId;
    Importance importance;
    Priority priority;

    switch (type) {
      case 'chat':
        channelId = 'chat_messages';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case 'payment':
        channelId = 'payments';
        importance = Importance.max;
        priority = Priority.max;
        break;
      case 'booking':
        channelId = 'bookings';
        importance = Importance.high;
        priority = Priority.high;
        break;
      default:
        channelId = 'general';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'chat_messages'
          ? 'Chat Messages'
          : channelId == 'payments'
          ? 'Payments'
          : channelId == 'bookings'
          ? 'Bookings'
          : 'General',
      channelDescription: 'Notifications for $channelId',
      importance: importance,
      priority: priority,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        contentTitle: notification.title,
      ),
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
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: _encodePayload(data),
    );
  }

  /// Handle notification tap (from system tray)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped');
    debugPrint('📦 Data: ${message.data}');

    final data = message.data;
    _navigateFromNotification(data);
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('👆 Local notification tapped');
    debugPrint('📦 Payload: ${response.payload}');

    if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      _navigateFromNotification(data);
    }
  }

  /// Navigate based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'];
    String? route;

    switch (type) {
      case 'chat':
        route = '/in-app-messaging-screen';
        break;
      case 'payment':
      case 'booking':
        route = '/booking-management';
        break;
      case 'review':
        route = '/artisan-profile-screen';
        break;
      default:
        route = '/posts-homepage';
    }

    if (route != null && onNotificationTap != null) {
      onNotificationTap!(route, data);
    }
  }

  /// Encode payload for local notifications
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode payload from local notifications
  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  /// Update badge count (iOS only - handled by system)
  Future<void> updateBadgeCount(int count) async {
    // Badge count is now handled automatically by the system
    // iOS: System manages badge based on notification count
    // Android: Handled by notification channels
    debugPrint('📊 Badge count: $count');
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('🧹 All notifications cleared');
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('✅ Unsubscribed from topic: $topic');
  }
}
