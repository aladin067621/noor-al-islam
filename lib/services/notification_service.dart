import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// خدمة الإشعارات المحلية — أذكار الصباح/المساء والأذكار المنبثقة
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // معرّفات ثابتة للإشعارات
  static const int morningId = 1001;
  static const int eveningId = 1002;
  static const int popupBaseId = 2000;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const settings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _plugin.initialize(settings);

      // طلب أذونات أندرويد 13+
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();

      _ready = true;
    } catch (_) {
      // المنصات غير المدعومة (الويب/سطح المكتب) — تجاهل بهدوء
      _ready = false;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'adhkar_channel',
          'تذكير الأذكار',
          channelDescription: 'إشعارات أذكار الصباح والمساء والأذكار المنبثقة',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// جدولة تذكير يومي متكرر في وقت محدد
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(time.hour, time.minute),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // يوميًا
    );
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id);
  }

  Future<void> scheduleMorning(TimeOfDay time) => scheduleDaily(
        id: morningId,
        title: 'أذكار الصباح',
        body: 'حان وقت أذكار الصباح — لا تنسَ ذكر الله',
        time: time,
      );

  Future<void> scheduleEvening(TimeOfDay time) => scheduleDaily(
        id: eveningId,
        title: 'أذكار المساء',
        body: 'حان وقت أذكار المساء — اطمئن قلبك بذكر الله',
        time: time,
      );

  /// عرض إشعار فوري بذكر عشوائي من القائمة (للأذكار المنبثقة)
  Future<void> showRandomDhikr(List<String> adhkar) async {
    if (!_ready || adhkar.isEmpty) return;
    final dhikr = adhkar[Random().nextInt(adhkar.length)];
    await _plugin.show(popupBaseId, 'تذكير بالذكر', dhikr, _details);
  }

  /// إلغاء كل الإشعارات
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }
}
