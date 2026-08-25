import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../utils/theme.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  int _viewYear = 0;
  int _viewMonth = 1;
  late final HijriCalendar _today = HijriCalendar.now();

  static const List<String> _monthNames = [
    '', 'محرّم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
    'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];

  static const List<String> _weekDays = ['أحد', 'إثنين', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];

  static const Map<int, List<Map<String, String>>> _islamicEvents = {
    1: [
      {'day': '1', 'title': 'رأس السنة الهجرية', 'desc': 'بداية السنة الهجرية الجديدة'},
      {'day': '10', 'title': 'يوم عاشوراء', 'desc': 'يوم صيام عاشوراء'},
    ],
    3: [
      {'day': '12', 'title': 'المولد النبوي', 'desc': 'ذكرى مولد النبي صلى الله عليه وسلم'},
    ],
    7: [
      {'day': '27', 'title': 'الإسراء والمعراج', 'desc': 'ذكرى ليلة الإسراء والمعراج'},
    ],
    8: [
      {'day': '15', 'title': 'ليلة النصف من شعبان', 'desc': 'ليلة مباركة'},
    ],
    9: [
      {'day': '1', 'title': 'بداية رمضان', 'desc': 'شهر الصيام'},
      {'day': '27', 'title': 'ليلة القدر', 'desc': 'خير من ألف شهر'},
    ],
    10: [
      {'day': '1', 'title': 'عيد الفطر', 'desc': 'عيد الفطر المبارك'},
    ],
    12: [
      {'day': '9', 'title': 'يوم عرفة', 'desc': 'يوم عرفة'},
      {'day': '10', 'title': 'عيد الأضحى', 'desc': 'عيد الأضحى المبارك'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _viewYear = _today.hYear;
    _viewMonth = _today.hMonth;
  }

  int get _daysInMonth => HijriCalendar().getDaysInMonth(_viewYear, _viewMonth);

  void _prevMonth() {
    setState(() {
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear -= 1;
      } else {
        _viewMonth -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear += 1;
      } else {
        _viewMonth += 1;
      }
    });
  }

  void _goToToday() {
    setState(() {
      _viewYear = _today.hYear;
      _viewMonth = _today.hMonth;
    });
  }

  bool _isToday(int day) =>
      day == _today.hDay && _viewMonth == _today.hMonth && _viewYear == _today.hYear;

  @override
  Widget build(BuildContext context) {
    final events = _islamicEvents[_viewMonth] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقويم الهجري'),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text('اليوم', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTodayCard(),
            const SizedBox(height: 16),
            _buildMonthHeader(),
            const SizedBox(height: 12),
            _buildWeekdayHeader(),
            const SizedBox(height: 4),
            _buildCalendarGrid(),
            if (events.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildEventsSection(events),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('اليوم', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '${_today.hDay} ${_monthNames[_today.hMonth]} ${_today.hYear}',
            style: const TextStyle(
              fontFamily: AppTheme.quranFontFamily,
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getWeekdayName(DateTime.now().weekday),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const names = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return names[weekday - 1];
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: _prevMonth),
        Column(
          children: [
            Text(
              _monthNames[_viewMonth],
              style: const TextStyle(
                fontFamily: AppTheme.quranFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            Text('$_viewYear هـ',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: _nextMonth),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: _weekDays
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: d == 'جمع' ? AppTheme.gold : Colors.grey[600],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final cells = <Widget>[];

    int startWeekday = 6;
    try {
      final gregDate =
          HijriCalendar().hijriToGregorian(_viewYear, _viewMonth, 1);
      startWeekday = gregDate.weekday % 7;
    } catch (_) {}

    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= _daysInMonth; day++) {
      final isToday = _isToday(day);
      cells.add(
        Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isToday ? AppTheme.primaryGreen : null,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Colors.white : null,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }

  Widget _buildEventsSection(List<Map<String, String>> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('مناسبات هذا الشهر',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...events.map((e) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.gold.withOpacity(0.15),
                  child: Text(e['day']!,
                      style: const TextStyle(
                          color: AppTheme.gold, fontWeight: FontWeight.bold)),
                ),
                title: Text(e['title']!,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(e['desc']!),
              ),
            )),
      ],
    );
  }
}
