import 'dart:async';

import 'package:flutter/material.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri/hijri_calendar.dart';

import '../services/location_service.dart';
import '../utils/theme.dart';
import '../screens/prayer/prayer_times_screen.dart';

/// لوحة معلومات عائمة في الصفحة الرئيسية: الصلاة التالية مع العدّ التنازلي
/// ومؤشرات غداً صيام (الاثنين / الخميس / الأيام البيض) والجمعة.
class HomeStatusPanel extends StatefulWidget {
  const HomeStatusPanel({super.key});

  @override
  State<HomeStatusPanel> createState() => _HomeStatusPanelState();
}

class _HomeStatusPanelState extends State<HomeStatusPanel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    LocationService.instance.load();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocationService.instance,
      builder: (context, _) {
        final loc = LocationService.instance.saved;
        if (loc == null) return const SizedBox.shrink();

        PrayerTimes? pt;
        try {
          final params = CalculationMethodParameters.muslimWorldLeague()
            ..madhab = Madhab.shafi;
          pt = PrayerTimes(
            coordinates: Coordinates(loc.latitude, loc.longitude),
            date: DateTime.now(),
            calculationParameters: params,
          );
        } catch (_) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        final nextPrayer = _nextPrayer(pt, now);
        final days = _fastingIndicators(now);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nextPrayer != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'الصلاة التالية: ${nextPrayer.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      const Spacer(),
                      if (nextPrayer.remaining != null)
                        Text(
                          _fmtDur(nextPrayer.remaining!),
                          style: const TextStyle(
                            fontFamily: AppTheme.quranFontFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                    ],
                  ),
                ],
                if (days.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...days.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(d.icon, size: 16, color: AppTheme.gold),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              d.label,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NextPrayerInfo {
  final String name;
  final Duration? remaining;
  const _NextPrayerInfo(this.name, this.remaining);
}

class _FastingIndicator {
  final IconData icon;
  final String label;
  const _FastingIndicator(this.icon, this.label);
}

_NextPrayerInfo? _nextPrayer(PrayerTimes pt, DateTime now) {
  final entries = <String, DateTime?>{
    'الفجر': pt.fajr,
    'الظهر': pt.dhuhr,
    'العصر': pt.asr,
    'المغرب': pt.maghrib,
    'العشاء': pt.isha,
  };
  for (final e in entries.entries) {
    final t = e.value?.toLocal();
    if (t != null && t.isAfter(now)) {
      return _NextPrayerInfo(e.key, t.difference(now));
    }
  }
  final fajr = pt.fajr?.toLocal();
  if (fajr != null) {
    final next = fajr.add(const Duration(days: 1));
    return _NextPrayerInfo('الفجر', next.difference(now));
  }
  return null;
}

List<_FastingIndicator> _fastingIndicators(DateTime now) {
  final indicators = <_FastingIndicator>[];

  final todayH = HijriCalendar.fromDate(now);
  final tomorrowH = HijriCalendar.fromDate(now.add(const Duration(days: 1)));
  final dow = now.weekday;
  final tomorrowDow = now.add(const Duration(days: 1)).weekday;

  if (tomorrowDow == DateTime.monday) {
    indicators.add(const _FastingIndicator(
      Icons.wb_sunny,
      'غداً الاثنين — سُنّة صيامه',
    ));
  }
  if (tomorrowDow == DateTime.thursday) {
    indicators.add(const _FastingIndicator(
      Icons.wb_sunny,
      'غداً الخميس — سُنّة صيامه',
    ));
  }
  if ({13, 14, 15}.contains(tomorrowH.hDay)) {
    indicators.add(const _FastingIndicator(
      Icons.nights_stay,
      'غداً من الأيام البيض — سُنّة صيامه',
    ));
  }
  if ({13, 14, 15}.contains(todayH.hDay)) {
    indicators.add(const _FastingIndicator(
      Icons.check_circle_outline,
      'اليوم من الأيام البيض — صيامه سُنّة',
    ));
  }
  if (dow == DateTime.friday) {
    indicators.add(const _FastingIndicator(
      Icons.auto_stories,
      'اليوم الجمعة — سُنّة قراءة سورة الكهف',
    ));
  }
  return indicators;
}

String _fmtDur(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '${h} س ${m} د';
  return '${m} د';
}
