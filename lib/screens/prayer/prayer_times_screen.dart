import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../utils/theme.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

const List<String> _hijriMonths = [
  '', 'محرّم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
  'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
  'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
];

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

  Map<String, double> _computeTimes(double lat, double lon) {
    final now = DateTime.now();
    final tzHours = now.timeZoneOffset.inMinutes / 60.0;
    final calc = _SolarCalc(now.year, now.month, now.day, lat, lon);

    final dhuhrUtc = calc.midDayUtc();
    final fajrUtc = calc.angleHour(-18.0, morning: true, refUtc: dhuhrUtc);
    final sunriseUtc = calc.angleHour(-0.833, morning: true, refUtc: dhuhrUtc);
    final asrUtc = calc.asrUtc(dhuhrUtc);
    final maghribUtc = calc.angleHour(-0.833, morning: false, refUtc: dhuhrUtc);
    final ishaUtc = calc.angleHour(-18.0, morning: false, refUtc: dhuhrUtc);

    double local(double utcHours) {
      var t = utcHours + tzHours - lon / 15.0;
      t = t % 24.0;
      if (t < 0) t += 24.0;
      return t;
    }

    return {
      'الفجر': local(fajrUtc),
      'الشروق': local(sunriseUtc),
      'الظهر': local(dhuhrUtc),
      'العصر': local(asrUtc),
      'المغرب': local(maghribUtc),
      'العشاء': local(ishaUtc),
    };
  }

  String _fmt(double hours) {
    final h = hours.floor() % 24;
    var m = ((hours - hours.floor()) * 60).round();
    var hh = h;
    if (m == 60) { m = 0; hh = (h + 1) % 24; }
    return '${hh.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.now();

    return Scaffold(
      appBar: AppBar(title: const Text('مواقيت الصلاة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(hijri),
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

  Widget _buildContent(HijriCalendar hijri) {
    final times = _computeTimes(_position!.latitude, _position!.longitude);

    final iconsColors = <String, (IconData, Color)>{
      'الفجر': (Icons.nightlight_round, const Color(0xFF1A237E)),
      'الشروق': (Icons.wb_sunny, const Color(0xFFFF9800)),
      'الظهر': (Icons.brightness_high, const Color(0xFFFFC107)),
      'العصر': (Icons.wb_cloudy, const Color(0xFFFF6F00)),
      'المغرب': (Icons.nights_stay, const Color(0xFFE65100)),
      'العشاء': (Icons.dark_mode, const Color(0xFF4A148C)),
    };

    final order = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    final prayers = [
      for (final name in order)
        _PrayerTime(name, _fmt(times[name]!), iconsColors[name]!.$1, iconsColors[name]!.$2),
    ];

    final now = DateTime.now();
    String nextPrayer = 'الفجر';
    for (final p in prayers) {
      if (p.name == 'الشروق') continue;
      final parts = p.time.split(':');
      final t = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (t.isAfter(now)) { nextPrayer = p.name; break; }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${hijri.hDay} ${_hijriMonths[hijri.hMonth]} ${hijri.hYear}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: AppTheme.quranFontFamily,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الموقع: ${_position!.latitude.toStringAsFixed(2)}° , ${_position!.longitude.toStringAsFixed(2)}°',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
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

class _SolarCalc {
  static const double _deg = 180.0 / math.pi;

  final double _jdBase;
  final double _lat;
  final double _lng;

  _SolarCalc(int year, int month, int day, this._lat, this._lng)
      : _jdBase = _julian(year, month, day);

  static double _julian(int y, int m, int d) {
    if (m <= 2) { y -= 1; m += 12; }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d + b - 1524.5;
  }

  static double _fixAngle(double a) {
    var r = a % 360.0;
    if (r < 0) r += 360.0;
    return r;
  }

  static double _fixHour(double a) {
    var r = a % 24.0;
    if (r < 0) r += 24.0;
    return r;
  }

  /// Returns [declination in degrees, equation-of-time in hours].
  List<double> _sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * math.sin(g / _deg) + 0.020 * math.sin(2 * g / _deg));
    final e = 23.439 - 0.00000036 * d;
    final ra = _fixAngle(math.atan2(math.cos(e / _deg) * math.sin(l / _deg),
            math.cos(l / _deg)) *
        _deg) /
        15.0;
    final decl = math.asin(math.sin(e / _deg) * math.sin(l / _deg)) * _deg;
    final eqt = q / 15.0 - ra;
    return [decl, eqt];
  }

  /// Solar noon in UTC hours for today's date at this longitude.
  double midDayUtc() {
    final jd = _jdBase - _lng / (15.0 * 24.0);
    final pos = _sunPosition(jd + 0.5 - _lng / 360.0);
    return _fixHour(12.0 - pos[1]);
  }

  double _hourAngleFor(double angleDeg, double decl) {
    final cosH =
        (-math.sin(angleDeg / _deg) - math.sin(decl / _deg) * math.sin(_lat / _deg)) /
            (math.cos(decl / _deg) * math.cos(_lat / _deg));
    if (cosH > 1 || cosH < -1) return double.nan;
    return math.acos(cosH) * _deg / 15.0;
  }

  /// Time when sun reaches [angleDeg] altitude, in UTC hours.
  double angleHour(double angleDeg, {required bool morning, required double refUtc}) {
    final jd = _jdBase - _lng / (15.0 * 24.0);
    final pos = _sunPosition(jd + (refUtc / 24.0));
    final ha = _hourAngleFor(angleDeg, pos[0]);
    final base = _fixHour(12.0 - pos[1]);
    if (ha.isNaN) {
      return morning ? base - 6.0 : base + 6.0;
    }
    return _fixHour(morning ? base - ha : base + ha);
  }

  /// Asr (Shafi'i, shadow factor 1) in UTC hours.
  double asrUtc(double refUtc) {
    final jd = _jdBase - _lng / (15.0 * 24.0);
    final pos = _sunPosition(jd + (refUtc / 24.0));
    final decl = pos[0];
    final angle =
        -(math.atan(1.0 / (1.0 + math.tan(((_lat - decl).abs()) / _deg)))) * _deg;
    final ha = _hourAngleFor(angle, decl);
    final base = _fixHour(12.0 - pos[1]);
    if (ha.isNaN) return _fixHour(base + 3.0);
    return _fixHour(base + ha);
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
                child: const Text('التالية',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            const SizedBox(width: 8),
            Text(
              prayer.time,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isNext ? AppTheme.primaryGreen : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
