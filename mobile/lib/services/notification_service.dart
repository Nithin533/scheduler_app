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
  static void Function(Map<String, dynamic>? data)? onNotificationTap;

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
          onNotificationTap?.call({'payload': response.payload});
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
      _handleTap(initialMessage);
    }

    _initialized = true;
  }

  static void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
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
    onNotificationTap?.call(message.data);
  }
}
