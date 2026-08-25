import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:adhan_dart/adhan_dart.dart';
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

  String _fmt(DateTime utcTime) {
    final local = utcTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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
    final coordinates = Coordinates(_position!.latitude, _position!.longitude);
    final params = CalculationMethodParameters.muslimWorldLeague();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: DateTime.now(),
      calculationParameters: params,
    );

    final prayers = [
      _PrayerTime('الفجر', _fmt(prayerTimes.fajr!), Icons.nightlight_round, const Color(0xFF1A237E)),
      _PrayerTime('الشروق', _fmt(prayerTimes.sunrise!), Icons.wb_sunny, const Color(0xFFFF9800)),
      _PrayerTime('الظهر', _fmt(prayerTimes.dhuhr!), Icons.brightness_high, const Color(0xFFFFC107)),
      _PrayerTime('العصر', _fmt(prayerTimes.asr!), Icons.wb_cloudy, const Color(0xFFFF6F00)),
      _PrayerTime('المغرب', _fmt(prayerTimes.maghrib!), Icons.nights_stay, const Color(0xFFE65100)),
      _PrayerTime('العشاء', _fmt(prayerTimes.isha!), Icons.dark_mode, const Color(0xFF4A148C)),
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
