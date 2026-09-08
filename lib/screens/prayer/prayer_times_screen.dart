import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/location_service.dart';
import '../../utils/theme.dart';
import '../../widgets/location_picker.dart';

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
  String? _error;

  int _methodIndex = 0;
  int _dayOffset = 0;

  // إذاعة الأذان
  bool _adhanEnabled = false;
  bool _adhanLoading = false;
  final AudioPlayer _adhanPlayer = AudioPlayer();

  // نص "الأذان يعمل الآن": آخر صلاة تم تشغيل أذانها (سورة لقمع تكرار التشغيل)
  String? _lastAdhanPrayer;

  // تحديث عدّاد الوقت كل دقيقة
  Timer? _ticker;

  static const String _adhanUrl =
      'https://alfurqan.online/api/v1/athan/1a014366658c';

  static const List<Map<String, String>> _methods = [
    {'name': 'رابطة العالم الإسلامي', 'desc': 'زاوية 18°'} ,
    {'name': 'أم القرى (مكة)', 'desc': '18.5° والعشاء بعد 90 دقيقة'} ,
    {'name': 'الهيئة المصرية', 'desc': '19.5°'} ,
  ];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _adhanPlayer.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final service = LocationService.instance;
    await service.load();
    if (!mounted) return;
    // موقع محفوظ — نعرض المواقيت فورًا دون طلب إذن أو انتظار GPS
    if (service.saved != null) {
      await _loadAdhanPref();
      _startTicker();
      return;
    }
    // لا موقع محفوظ — حاول تحديده من GPS مرة واحدة
    final err = await service.refreshFromGps();
    if (!mounted) return;
    setState(() => _error = err);
  }

  Future<void> _loadAdhanPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _adhanEnabled = prefs.getBool('adhan_enabled') ?? false;
    });
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() {});
      _maybeFlashAdhan();
    });
  }

  /// عند تفعيل الأذان: يفحص إن دخل وقت صلاةٍ ما الآن ثم يشغّل الأذان مرة واحدة
  Future<void> _maybeFlashAdhan() async {
    if (!_adhanEnabled || _dayOffset != 0) return;
    final loc = LocationService.instance.saved;
    if (loc == null) return;
    final now = DateTime.now();
    final pt = PrayerTimes(
      coordinates: Coordinates(loc.latitude, loc.longitude),
      date: now,
      calculationParameters: _paramsForMethod(_methodIndex),
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
      final parts = _fmt(t).split(':');
      final local = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      final windowEnd = local.add(const Duration(minutes: 1));
      if (!now.isBefore(local) && now.isBefore(windowEnd)) {
        final key = _keyFor(now, e.key);
        if (_lastAdhanPrayer == key) continue;
        _lastAdhanPrayer = key;
        await _playAdhan();
      }
    }
  }

  String _keyFor(DateTime d, String name) =>
      '${d.year}-${d.month}-${d.day}-$name';

  Future<void> _toggleAdhan() async {
    final enable = !_adhanEnabled;
    setState(() => _adhanEnabled = enable);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_enabled', enable);
    if (!enable) {
      await _adhanPlayer.stop();
      if (mounted) setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تفعيل الأذان: سيُشغَّل الأذان عند دخول وقت كل صلاة'),
          duration: Duration(seconds: 3),
        ));
      }
    }
  }

  /// تشغيل الأذان (عبر تدفق mp3 — دون تحميل الملف)
  Future<void> _playAdhan() async {
    setState(() => _adhanLoading = true);
    try {
      await _adhanPlayer.stop();
      await _adhanPlayer.play(UrlSource(_adhanUrl));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذر تشغيل الأذان — تحقق من اتصالك بالإنترنت'),
        ));
      }
    } finally {
      if (mounted) setState(() => _adhanLoading = false);
    }
  }

  void _stopAdhan() {
    _adhanPlayer.stop();
    setState(() {});
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

  String _nextPrayerName(List<_PrayerTime> prayers, DateTime now) {
    for (final p in prayers) {
      if (p.name == 'الشروق') continue;
      final parts = p.time.split(':');
      final t = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (t.isAfter(now)) return p.name;
    }
    // كل الصلوات مرّت اليوم → التالية صلاة الفجر
    return 'الفجر';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        actions: [
          IconButton(
            tooltip: _adhanEnabled ? 'إيقاف الأذان' : 'تشغيل الأذان',
            icon: _adhanLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _adhanEnabled
                        ? Icons.volume_up
                        : Icons.volume_off_outlined,
                    color: _adhanEnabled ? AppTheme.gold : null,
                  ),
            onPressed: _toggleAdhan,
          ),
          PopupMenuButton<String>(
            tooltip: 'التحكم في الأذان',
            onSelected: (v) {
              if (v == 'play') {
                _playAdhan();
              } else if (v == 'stop') {
                _stopAdhan();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'play',
                child: ListTile(
                  leading: Icon(Icons.play_circle_outline),
                  title: Text('تشغيل الأذان الآن'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'stop',
                child: ListTile(
                  leading: Icon(Icons.stop_circle_outlined),
                  title: Text('إيقاف الأذان'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'تغيير الموقع',
            icon: const Icon(Icons.my_location),
            onPressed: () => showLocationPicker(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: LocationService.instance,
        builder: (context, _) {
          final loc = LocationService.instance.saved;
          if (loc == null) {
            if (_error != null) return _buildError();
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(loc);
        },
      ),
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
              onPressed: () async {
                setState(() => _error = null);
                final err = await LocationService.instance.refreshFromGps();
                if (!mounted) return;
                setState(() => _error = err);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => showLocationPicker(context),
              icon: const Icon(Icons.location_city),
              label: const Text('اختيار مدينة يدويًا'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SavedLocation loc) {
    final coordinates = Coordinates(loc.latitude, loc.longitude);
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

    // تفعيل الأذان تلقائيًا عند دخول وقت الصلاة (مرة واحدة لكل صلاة)
    // — يُدار من المؤقّت الدوري، لا من دورة البناء
    final now = DateTime.now();
    final nextPrayer = _dayOffset == 0 ? _nextPrayerName(prayers, now) : '';

    final dayLabel = _dayOffset == 0
        ? 'اليوم'
        : _dayOffset == 1
            ? 'غداً'
            : _dayOffset == 2
                ? 'بعد غد'
                : 'بعد $_dayOffset أيام';

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
                  'الموقع: ${loc.label}',
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
          ...prayers.map((p) => _PrayerTile(
                prayer: p,
                isNext: p.name == nextPrayer,
                now: now,
                dayOffset: _dayOffset,
              )),
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
  final DateTime now;
  final int dayOffset;

  const _PrayerTile({
    required this.prayer,
    required this.isNext,
    required this.now,
    required this.dayOffset,
  });

  /// فرق الوقت: مرّ (elapsed) أو بقي (remaining) — الأوقات تُحسب ليوم العرض
  _CountDiff? _diff() {
    final parts = prayer.time.split(':');
    final t = DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
    final diff = now.difference(t);
    if (diff.inSeconds > -30 && diff.inSeconds <= 30) {
      return _CountDiff('الآن', isPast: false);
    }
    if (diff.isNegative) {
      // بقي بعض الوقت → upcoming
      final abs = -diff;
      return _CountDiff(_fmtDur(abs), isPast: false);
    }
    // مرّ الوقت → elapsed
    return _CountDiff(_fmtDur(diff), isPast: true);
  }

  String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h} س ${m} د';
    return '${m} د';
  }

  @override
  Widget build(BuildContext context) {
    final diff = dayOffset == 0 ? _diff() : null;
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
        subtitle: diff != null
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(
                      diff.isPast ? Icons.check_circle_outline : Icons.schedule,
                      size: 14,
                      color: diff.isPast ? Colors.grey : AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      diff.label == 'الآن'
                          ? 'حان وقت الصلاة الآن'
                          : (diff.isPast
                              ? 'مرّ عليه ${diff.label}'
                              : 'بقي ${diff.label}'),
                      style: TextStyle(
                        fontSize: 12,
                        color: diff.isPast
                            ? Colors.grey
                            : AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : null,
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

class _CountDiff {
  final String label;
  final bool isPast;
  const _CountDiff(this.label, {required this.isPast});
}
