import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../utils/theme.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Position? _position;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _error = 'خدمة الموقع غير مفعّلة'; _loading = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _error = 'الرجاء تفعيل صلاحية الموقع'; _loading = false; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _error = 'صلاحية الموقع ممنوعة نهائياً — يُرجى تفعيلها من الإعدادات'; _loading = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() { _position = pos; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'فشل في تحديد الموقع'; _loading = false; });
    }
  }

  List<_PrayerTime> _calculate(double lat, double lon) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;

    double decl = 23.45 * (360 / 365) * (284 + dayOfYear);
    decl = decl * 3.141592653589793 / 180;
    final declDeg = decl * 180 / 3.141592653589793;

    final latRad = lat * 3.141592653589793 / 180;

    final eqt = -17.2 * (3.141592653589793 / 180) *
        (4 * (3.141592653589793 / 180) * dayOfYear + 0.0357 * (3.141592653589793 / 180) *
            (367 * dayOfYear - 710));
    final eqtMin = eqt * 4 / 3.141592653589793;

    double cosHA(double angle) {
      final a = -0.0145 - (latRad > 0 ? 0.1449 : -0.1449) * 3.141592653589793 / 180;
      final ha = (a - (latRad > 0 ? decl : -decl)) / latRad.abs();
      return ha.clamp(-1.0, 1.0);
    }

    double timeAngle = -0.0145 - decl;
    final haSunrise = -5.0 * 3.141592653589793 / 180;
    final haSunset = 5.0 * 3.141592653589793 / 180;

    final sinHA = -(0.0145 + decl * latRad / (90 * 3.141592653589793 / 180) * (lat > 0 ? 1 : -1));
    final haMaghrib = -(lat > 0 ? 0.833 : -0.833) * 3.141592653589793 / 180;

    final dhuhaAngle = (lat > 0 ? 1 : -1) * 1.0 * 3.141592653589793 / 180;

    double hourAngle(double altitudeDeg) {
      final altRad = altitudeDeg * 3.141592653589793 / 180;
      final cosHAVal = (altRad.sin - latRad.sin * decl.sin) / (latRad.cos * decl.cos);
      return cosHAVal.clamp(-1.0, 1.0).acos();
    }

    final sunDecl = declDeg;

    final fajrAlt = -18.0 * 3.141592653589793 / 180;
    final sunriseAlt = -0.833 * 3.141592653589793 / 180;
    final asrAlt1 = 0.0;
    final ishaAlt = -18.0 * 3.141592653589793 / 180;

    final List<double> times = [];

    final dhuhaHA = hourAngle(1.0);
    times.add(12 + (eqtMin - lon / 15 + 360) / 360 * 24 - dhuhaHA * 180 / (15 * 3.141592653589793));

    final fajrHA = hourAngle(-18.0);
    times.add(12 + (eqtMin - lon / 15 + 360) / 360 * 24 - fajrHA * 180 / (15 * 3.141592653589793));

    final sunriseHA = hourAngle(-0.833);
    times.add(12 + (eqtMin - lon / 15 + 360) / 360 * 24 - sunriseHA * 180 / (15 * 3.141592653589793));

    times.add(12 + (eqtMin - lon / 15) * 24 / 360);

    final asrAngle = (lat > 0 ? 1 : -1).toDouble();
    final asrHA = hourAngle(atan(1.0 / (1 + (lat.abs() - declDeg.abs()).abs().clamp(0, 89))) * 180 / 3.141592653589793);
    times.add(12 + (eqtMin - lon / 15 + 360) / 360 * 24 + asrHA * 180 / (15 * 3.141592653589793));

    final maghribHA = hourAngle(-0.833);
    times.add(12 + (eqtMin - lon / 15 + 360) / 360 * 24 + maghribHA * 180 / (15 * 3.141592653589793));

    final ishaHA = hourAngle(-18.0);
    times.add(12 + (eqtMin - lon / 15 + 360) / 360 * 24 + ishaHA * 180 / (15 * 3.141592653589793));

    String fmt(double h) {
      final hour = h.floor();
      final min = ((h - hour) * 60).round();
      final hh = hour % 24;
      return '${hh.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
    }

    return [
      _PrayerTime('الشروق', fmt(times[2]), Icons.wb_sunny, const Color(0xFFFF9800)),
      _PrayerTime('الظهر', fmt(times[3]), Icons.brightness_high, const Color(0xFFFFC107)),
      _PrayerTime('العصر', fmt(times[4]), Icons.wb_cloudy, const Color(0xFFFF6F00)),
      _PrayerTime('المغرب', fmt(times[5]), Icons.nights_stay, const Color(0xFFE65100)),
      _PrayerTime('العشاء', fmt(times[6]), Icons.dark_mode, const Color(0xFF4A148C)),
      _PrayerTime('الفجر', fmt(times[1]), Icons.nightlight_round, const Color(0xFF1A237E)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.now();
    final hijriMonths = ['', 'محرّم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
      'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];

    return Scaffold(
      appBar: AppBar(title: const Text('مواقيت الصلاة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(hijri, hijriMonths),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() { _loading = true; _error = null; _init(); }),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(HijriCalendar hijri, List<String> hijriMonths) {
    final prayers = _calculate(_position!.latitude, _position!.longitude);
    final now = DateTime.now();

    String nextPrayer = '';
    for (final p in prayers) {
      final parts = p.time.split(':');
      final t = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      if (t.isAfter(now)) {
        nextPrayer = p.name;
        break;
      }
    }
    if (nextPrayer.isEmpty) nextPrayer = 'الفجر';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${hijri.hDay} ${hijriMonths[hijri.hMonth]} ${hijri.hYear}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: AppTheme.quranFontFamily,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الموقع: ${_position!.latitude.toStringAsFixed(2)}°, ${_position!.longitude.toStringAsFixed(2)}°',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...prayers.map((p) => _PrayerTile(prayer: p, isNext: p.name == nextPrayer)),
        ],
      ),
    );
  }
}

class _PrayerTime {
  final String name;
  final String time;
  final IconData icon;
  final Color color;

  const _PrayerTime(this.name, this.time, this.icon, this.color);
}

class _PrayerTile extends StatelessWidget {
  final _PrayerTime prayer;
  final bool isNext;

  const _PrayerTile({required this.prayer, required this.isNext});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNext
            ? BorderSide(color: AppTheme.gold, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: prayer.color.withOpacity(0.15),
          child: Icon(prayer.icon, color: prayer.color, size: 22),
        ),
        title: Text(
          prayer.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isNext ? AppTheme.primaryGreen : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNext)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('التالية', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            const SizedBox(width: 8),
            Text(
              prayer.time,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: isNext ? AppTheme.primaryGreen : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
