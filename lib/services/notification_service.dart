import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/order.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDeliveryReminder(Order order) async {
    if (order.id == null) return;

    // 2 gün önce saat 09:00'da bildirim gönder
    final reminderDate = order.deliveryDate.subtract(const Duration(days: 2));
    final scheduledTime = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
      0,
    );

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      order.id!,
      'Teslim tarihi yaklaşıyor!',
      '${order.customerName} - ${order.productName} için 2 gün kaldı.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'delivery_reminders',
          'Teslim Hatırlatıcıları',
          channelDescription: 'Sipariş teslim tarihi yaklaşınca bildirir',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // 1 gün önce saat 09:00'da ikinci bildirim
    final reminderDate1 = order.deliveryDate.subtract(const Duration(days: 1));
    final scheduledTime1 = tz.TZDateTime(
      tz.local,
      reminderDate1.year,
      reminderDate1.month,
      reminderDate1.day,
      9,
      0,
    );

    if (scheduledTime1.isAfter(tz.TZDateTime.now(tz.local))) {
      await _plugin.zonedSchedule(
        order.id! + 10000,
        'Teslim tarihi yarın!',
        '${order.customerName} - ${order.productName} yarın teslim edilecek.',
        scheduledTime1,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'delivery_reminders',
            'Teslim Hatırlatıcıları',
            channelDescription: 'Sipariş teslim tarihi yaklaşınca bildirir',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelReminder(int orderId) async {
    await _plugin.cancel(orderId);
    await _plugin.cancel(orderId + 10000);
  }
}
