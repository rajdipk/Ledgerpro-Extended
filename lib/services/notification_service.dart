import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Private constructor
  NotificationService._();

  // Factory constructor for singleton
  factory NotificationService() {
    _instance ??= NotificationService._();
    return _instance!;
  }

  static NotificationService get instance => NotificationService();

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
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

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // Handle notification tap
        },
      );

      _isInitialized = initialized ?? false;
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> showLicenseExpiryNotification({
    required int licenseId,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
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

  Future<bool> scheduleLicenseExpiryNotification({
    required int licenseId,
    required DateTime expiryDate,
  }) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          debugPrint('Failed to initialize notifications');
          return false;
        }
      }

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

      return true;
    } catch (e) {
      debugPrint('Error scheduling license expiry notifications: $e');
      return false;
    }
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
    if (!_isInitialized) {
      await initialize();
    }
    // Cancel all notifications for this license (base ID * 2, *2+1, *2+2)
    await _notifications.cancel(licenseId * 2);
    await _notifications.cancel(licenseId * 2 + 1);
    await _notifications.cancel(licenseId * 2 + 2);
  }
}
