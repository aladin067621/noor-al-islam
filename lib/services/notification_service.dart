import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hijri/hijri_calendar.dart';
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

  // معرّفات تذكيرات السنن اليومية
  static const int fridayKahfId = 3001;
  static const int mondayFastId = 3002;
  static const int thursdayFastId = 3003;
  static const int whiteDayBaseId = 4000;
  static const int whiteDayCount = 36;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const settings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _plugin.initialize(settings);

      // لا تُطلب أذونات النظام هنا — تُعرض نافذة شرح أول تشغيل،
      // وتُطلب الأذونات بعد موافقة المستخدم.
      _ready = true;
    } catch (_) {
      // المنصات غير المدعومة (الويب/سطح المكتب) — تجاهل بهدوء
      _ready = false;
    }
  }

  /// طلب إذن الإشعارات يدويًا (يُستخدم عند أول تشغيل)
  Future<void> requestNotificationPermission() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } catch (_) {
      // تجاهل — المنصات التي لا تدعم الطلب
    }
  }

  /// طلب إذن التنبيهات الدقيقة (يُطلب بعد موافقة المستخدم في أول تشغيل)
  Future<void> requestExactAlarmsPermission() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {
      // تجاهل — المنصات التي لا تدعم الطلب
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

  /// جدولة تذكير أسبوعي متكرر في يوم ويوم من الأسبوع (1=الاثنين … 7=الأحد)
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required int weekday,
  }) async {
    if (!_ready) return;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day,
        time.hour, time.minute);
    final diff = (weekday - scheduled.weekday) % 7;
    scheduled = scheduled.add(Duration(days: diff));
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// جدولة تذكيرات الأيام البيض (13/14/15 من كل شهر هجري) لعدة أشهر قادمة.
  /// يُذكِّر مساء اليوم السابق لسرعة صيام الغد (النية قبل الفجر).
  Future<void> scheduleWhiteDays({int months = 12}) async {
    if (!_ready) return;
    if (months * 3 > whiteDayCount) months = whiteDayCount ~/ 3;
    final now = tz.TZDateTime.now(tz.local);
    final today = HijriCalendar.fromDate(now.toLocal());
    int id = whiteDayBaseId;

    for (int mi = 0; mi < months; mi++) {
      var hy = today.hYear;
      var hm = today.hMonth + mi;
      if (hm > 12) {
        hy += 1 + (hm - 1) ~/ 12;
        hm = ((hm - 1) % 12) + 1;
      }
      final cal = HijriCalendar();
      for (final d in [13, 14, 15]) {
        final date = cal.hijriToGregorian(hy, hm, d);
        final eve = tz.TZDateTime(tz.local, date.year, date.month, date.day, 21, 0)
            .subtract(const Duration(days: 1));
        if (eve.isBefore(now)) continue;
        id++;
        if (id > whiteDayBaseId + whiteDayCount) return;
        await _plugin.zonedSchedule(
          id,
          'الأيام البيض 13/14/15',
          'غداً من الأيام البيض — من الأفضل صيامه، فصيام ثلاثة أيام من كل شهر كصيام الدهر',
          eve,
          _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// جدولة جميع تذكيرات السنن اليومية (الجمعة/الاثنين/الخميس/الأيام البيض)
  Future<void> scheduleSunnahReminders() async {
    if (!_ready) return;
    await scheduleWeekly(
      id: fridayKahfId,
      title: 'مجيء يوم الجمعة',
      body: 'من الأفضل قراءة سورة الكهف — «من قرأ سورة الكهف يوم الجمعة أضاء له من النور ما بين الجمعتين»',
      time: const TimeOfDay(hour: 8, minute: 0),
      weekday: DateTime.friday,
    );
    await scheduleWeekly(
      id: mondayFastId,
      title: 'غداً الاثنين',
      body: 'من الأفضل صيامه — «تُعرَض الأعمال يوم الاثنين والخميس، فأحب أن يُعرَض عملي وأنا صائم»',
      time: const TimeOfDay(hour: 21, minute: 0),
      weekday: DateTime.monday,
    );
    await scheduleWeekly(
      id: thursdayFastId,
      title: 'غداً الخميس',
      body: 'من الأفضل صيامه — «تُعرَض الأعمال يوم الاثنين والخميس، فأحب أن يُعرَض عملي وأنا صائم»',
      time: const TimeOfDay(hour: 21, minute: 0),
      weekday: DateTime.thursday,
    );
    await scheduleWhiteDays();
  }

  /// إلغاء تذكيرات السنن اليومية
  Future<void> cancelSunnahReminders() async {
    if (!_ready) return;
    await _plugin.cancel(fridayKahfId);
    await _plugin.cancel(mondayFastId);
    await _plugin.cancel(thursdayFastId);
    for (int id = whiteDayBaseId + 1; id <= whiteDayBaseId + whiteDayCount; id++) {
      await _plugin.cancel(id);
    }
  }

  /// عرض إشعار فوري بذكر عشوائي من القائمة (للأذكار المنبثقة)
  Future<void> showRandomDhikr(List<String> adhkar) async {
    if (!_ready || adhkar.isEmpty) return;
    final dhikr = adhkar[Random().nextInt(adhkar.length)];
    await _plugin.show(popupBaseId, 'تذكير بالذكر', dhikr, _details);
  }

  /// جدولة الأذكار المنبثقة بشكل دوري بفترة حرّة (بالدقائق).
  /// تُلغى أي جدولة سابقة ثم تُعاد جدولتها بالفترة الجديدة.
  Future<void> schedulePopupDhikr(
      List<String> adhkar, int intervalMinutes) async {
    if (!_ready || adhkar.isEmpty) return;
    await _plugin.cancel(popupBaseId);
    if (intervalMinutes < 1) intervalMinutes = 1;
    final dhikr = adhkar[Random().nextInt(adhkar.length)];
    final now = tz.TZDateTime.now(tz.local);
    final start = now.add(Duration(minutes: intervalMinutes));
    await _plugin.zonedSchedule(
      popupBaseId,
      'تذكير بالذكر',
      dhikr,
      start,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      repeatInterval: Duration(minutes: intervalMinutes),
    );
  }

  /// إلغاء إشعارات الأذكار المنبثقة
  Future<void> cancelPopupDhikr() async {
    if (!_ready) return;
    await _plugin.cancel(popupBaseId);
  }

  /// إلغاء كل الإشعارات
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }
}
