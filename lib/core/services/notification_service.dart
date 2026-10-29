import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notifications.initialize(settings: initSettings);
      _initialized = true;
    } catch (_) {
      // Fallback gracefully if platform does not support notifications
    }
  }

  /// Plays an audio chime and posts an Android heads-up notification.
  static Future<void> showRestFinishedNotification({
    String title = 'Rest Period Finished!',
    String body = 'Time for your next set. Lightweight, baby!',
  }) async {
    await init();

    // 1. Audio chime & haptic alert
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.vibrate();
    } catch (_) {}

    // 2. Android lock-screen / heads-up notification
    try {
      const androidDetails = AndroidNotificationDetails(
        'rest_timer_channel',
        'Rest Timer Notifications',
        channelDescription: 'Alerts when your gym rest interval finishes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const details = NotificationDetails(android: androidDetails);
      await _notifications.show(
        id: 1001,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {}
  }

  static Future<void> cancelRestNotification() async {
    try {
      await _notifications.cancel(id: 1001);
    } catch (_) {}
  }
}
