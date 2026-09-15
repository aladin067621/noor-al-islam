import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

// مفاتيح مشتركة بين التطبيق وخدمة الأذان الأمامية
const String kAdhanFgEnabledKey = 'adhan_fg_enabled';
const String kAdhanFgLatKey = 'adhan_fg_lat';
const String kAdhanFgLngKey = 'adhan_fg_lng';
const String kAdhanFgMethodKey = 'adhan_fg_method';

// آخر صلاة تم تشغيل أذانها (يمنع التكرار، ويُشارك بين التطبيق والخدمة)
const String kAdhanLastPlayedKey = 'adhan_last_played';

const String _adhanUrl =
    'https://alfurqan.online/api/v1/athan/1a014366658c';

/// نقطة دخول الخدمة الأمامية: تُنفَّذ في عزل منفصل عن واجهة التطبيق.
@pragma('vm:entry-point')
void adhanTaskCallback() {
  FlutterForegroundTask.setTaskHandler(AdhanTaskHandler());
}

/// معالج مهمة الأذان الذي يعمل في الخلفية حتى خارج التطبيق.
class AdhanTaskHandler extends TaskHandler {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _tick();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_tick());
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _player.dispose();
  }

  Future<void> _tick() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(kAdhanFgLatKey);
      final lng = prefs.getDouble(kAdhanFgLngKey);
      final method = prefs.getInt(kAdhanFgMethodKey) ?? 0;
      if (lat == null || lng == null) return;

      final now = DateTime.now();
      final pt = PrayerTimes(
        coordinates: Coordinates(lat, lng),
        date: now,
        calculationParameters: _paramsForMethod(method),
      );

      final names = <String, DateTime?>{
        'الفجر': pt.fajr,
        'الظهر': pt.dhuhr,
        'العصر': pt.asr,
        'المغرب': pt.maghrib,
        'العشاء': pt.isha,
      };

      for (final e in names.entries) {
        final t = e.value;
        if (t == null) continue;
        final diff = now.difference(t);
        if (now.isBefore(t) || diff.inSeconds >= 180) continue;
        final key = _keyFor(now, e.key);
        if (prefs.getString(kAdhanLastPlayedKey) == key) continue;
        await prefs.setString(kAdhanLastPlayedKey, key);
        await _play();
        break;
      }
    } catch (_) {
      // لا نُسقط الخدمة عند أي خطأ مؤقت (انقطاع إنترنت، إلخ)
    }
  }

  Future<void> _play() async {
    try {
      await _player.stop();
      await _player.play(UrlSource(_adhanUrl));
    } catch (_) {}
  }

  String _keyFor(DateTime d, String name) =>
      '${d.year}-${d.month}-${d.day}-$name';
}

CalculationParameters _paramsForMethod(int index) {
  final CalculationParameters params;
  switch (index) {
    case 0:
      params = CalculationMethodParameters.muslimWorldLeague();
      break;
    case 1:
      params = CalculationMethodParameters.ummAlQura();
      break;
    default:
      params = CalculationMethodParameters.egyptian();
      break;
  }
  params.madhab = Madhab.shafi;
  return params;
}