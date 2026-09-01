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

  int _methodIndex = 0;
  int _dayOffset = 0;

  static const List<Map<String, String>> _methods = [
    {'name': 'رابطة العالم الإسلامي', 'desc': 'زاوية 18°'} ,
    {'name': 'أم القرى (مكة)', 'desc': '18.5° والعشاء بعد 90 دقيقة'} ,
    {'name': 'الهيئة المصرية', 'desc': '19.5°'} ,
  ];

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
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() { _position = pos; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'فشل في تحديد الموقع'; _loading = false; });
    }
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

  String _fmt(DateTime utcTime) {
    final local = utcTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'اختر طريقة الحساب',
            onPressed: _showMethodPicker,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  void _showMethodPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('طريقة حساب المواقيت',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ..._methods.asMap().entries.map((e) => RadioListTile<int>(
                  value: e.key,
                  groupValue: _methodIndex,
                  title: Text(e.value['name']!),
                  subtitle: Text(e.value['desc']!),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _methodIndex = v);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
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

  Widget _buildContent() {
    final coordinates = Coordinates(_position!.latitude, _position!.longitude);
    final targetDate = DateTime.now().add(Duration(days: _dayOffset));
    final hijriFrom = HijriCalendar.fromDate(targetDate);
    final params = _paramsForMethod(_methodIndex);

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: targetDate,
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
    if (_dayOffset == 0) {
      for (final p in prayers) {
        if (p.name == 'الشروق') continue;
        final parts = p.time.split(':');
        final t = DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
        if (t.isAfter(now)) { nextPrayer = p.name; break; }
      }
    } else {
      nextPrayer = '';
    }

    final dayLabel = _dayOffset == 0
        ? 'اليوم'
        : _dayOffset == 1
            ? 'غداً'
            : 'بعد غد';

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
                  '$dayLabel — ${hijriFrom.hDay} ${_hijriMonths[hijriFrom.hMonth]} ${hijriFrom.hYear}',
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_methods[_methodIndex]['name']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              TextButton.icon(
                onPressed: _showMethodPicker,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('تغيير الطريقة'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _dayOffset > 0
                      ? () => setState(() => _dayOffset--)
                      : null,
                  tooltip: 'اليوم السابق',
                ),
                Text(dayLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _dayOffset++),
                  tooltip: 'اليوم التالي',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...prayers.map((p) => _PrayerTile(prayer: p, isNext: p.name == nextPrayer)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppTheme.gold),
                    SizedBox(width: 8),
                    Text('تنبيه مهم',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'هذه المواقيت محسوبة بحسب موقعك وطريقة الحساب المختارة، وقد تختلف عن الأذان المحلي بفارق دقائق لاختلاف طرق الحساب وظروف المكان. '
                  'ينبغي للمصلي أن يتحرّى وقت الصلاة بنفسه، فالاحتياط للعبادة أولى، خاصة في الفجر والعشاء.',
                  style: TextStyle(height: 1.8, fontSize: 14),
                ),
              ],
            ),
          ),
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
