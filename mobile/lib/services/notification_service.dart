import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? fcmToken;
  static bool _initialized = false;

  /// Callback when user taps a notification
  static void Function(Map<String, dynamic>? data)? _onNotificationTap;
  static Map<String, dynamic>? _pendingTapData;

  static void Function(Map<String, dynamic>? data)? get onNotificationTap => _onNotificationTap;

  static set onNotificationTap(void Function(Map<String, dynamic>? data)? callback) {
    _onNotificationTap = callback;
    if (_pendingTapData != null) {
      _onNotificationTap?.call(_pendingTapData);
      _pendingTapData = null;
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp();

    // Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    fcmToken = await _fcm.getToken();

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((token) {
      fcmToken = token;
    });

    // Initialize local notifications channel (for foreground display)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _onNotificationTap?.call({'payload': response.payload});
        }
      },
    );

    // Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Background tap → navigate
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App opened from terminated state via notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (_onNotificationTap != null) {
        _handleTap(initialMessage);
      } else {
        _pendingTapData = initialMessage.data;
      }
    }

    _initialized = true;
  }

  static int _notificationId = 0;

  static void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      _notificationId++,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_reminders',
          'Schedule Reminders',
          channelDescription: 'Reminders for upcoming scheduled activities',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  static void _handleTap(RemoteMessage message) {
    if (onNotificationTap == null) return;
    onNotificationTap!.call(message.data);
  }
}
