import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );
  }

  Future<void> showLicenseExpiryNotification({
    required int licenseId,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'license_expiry',
      'License Expiry',
      channelDescription: 'Notifications about license expiry',
      importance: Importance.high,
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

    await _notifications.show(
      licenseId,
      title,
      body,
      details,
    );
  }

  Future<void> scheduleLicenseExpiryNotification({
    required int licenseId,
    required DateTime expiryDate,
  }) async {
    // Schedule notification 7 days before expiry
    final sevenDaysBefore = expiryDate.subtract(const Duration(days: 7));
    if (sevenDaysBefore.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: licenseId * 2,
        title: 'License Expiring Soon',
        body: 'Your license will expire in 7 days. Please renew to continue using all features.',
        scheduledDate: sevenDaysBefore,
      );
    }

    // Schedule notification 1 day before expiry
    final oneDayBefore = expiryDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: licenseId * 2 + 1,
        title: 'License Expires Tomorrow',
        body: 'Your license will expire tomorrow. Please renew now to avoid service interruption.',
        scheduledDate: oneDayBefore,
      );
    }

    // Schedule notification on expiry
    await _scheduleNotification(
      id: licenseId * 2 + 2,
      title: 'License Expired',
      body: 'Your license has expired. Please renew now to continue using all features.',
      scheduledDate: expiryDate,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'license_expiry',
      'License Expiry',
      channelDescription: 'Notifications about license expiry',
      importance: Importance.high,
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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelLicenseNotifications(int licenseId) async {
    // Cancel all notifications for this license (base ID * 2, *2+1, *2+2)
    await _notifications.cancel(licenseId * 2);
    await _notifications.cancel(licenseId * 2 + 1);
    await _notifications.cancel(licenseId * 2 + 2);
  }
}
