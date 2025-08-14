import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Counter to store and auto-increment ID
  static int _notificationId = 0;

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    _notificationId++; // Auto-increment ID

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ride_detail',
          'Ride Detail',
          channelDescription: 'This is for ride detail',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'notification_icon',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      _notificationId, // Unique ID each time
      title,
      body,
      details,
    );
  }
}
