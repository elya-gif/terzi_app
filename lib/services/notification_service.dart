import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/fitting.dart';
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

  Future<void> scheduleFittingReminder(Fitting fitting) async {
    if (fitting.id == null) return;

    // Prova günü sabah 08:00'de bildirim
    final scheduledTime = tz.TZDateTime(
      tz.local,
      fitting.fittingDate.year,
      fitting.fittingDate.month,
      fitting.fittingDate.day,
      8,
      0,
    );

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final notifId = fitting.id! + 20000;
    await _plugin.zonedSchedule(
      notifId,
      'Prova günü!',
      '${fitting.customerName} için bugün prova var.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fitting_reminders',
          'Prova Hatırlatıcıları',
          channelDescription: 'Prova günü sabahı bildirir',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Bir gün önce de hatırlatıcı
    final dayBefore = scheduledTime.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await _plugin.zonedSchedule(
        notifId + 1,
        'Yarın prova var!',
        '${fitting.customerName} için yarın prova randevusu.',
        dayBefore,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fitting_reminders',
            'Prova Hatırlatıcıları',
            channelDescription: 'Prova günü sabahı bildirir',
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

  Future<void> cancelFittingReminder(int fittingId) async {
    await _plugin.cancel(fittingId + 20000);
    await _plugin.cancel(fittingId + 20001);
  }
}
