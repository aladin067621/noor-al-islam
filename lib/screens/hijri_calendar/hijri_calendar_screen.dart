import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../utils/theme.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late HijriCalendar _currentMonth;
  final _today = HijriCalendar.now();

  static const List<String> _monthNames = [
    '', 'محرّم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
    'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];

  static const List<String> _weekDays = ['أحد', 'إثنين', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];

  static const Map<String, List<Map<String, dynamic>>> _islamicEvents = {
    'محرّم': [
      {'day': 1, 'title': 'رأس السنة الهجرية', 'desc': 'أول محرم'},
    ],
    'صفر': [
      {'day': 10, 'title': 'يوم عاشوراء', 'desc': 'صيام يوم عاشوراء'},
    ],
    'ربيع الأول': [
      {'day': 12, 'title': 'المولد النبوي', 'desc': 'ولد النبي صلى الله عليه وسلم'},
    ],
    'ربيع الثاني': [
      {'day': 11, 'title': 'المولد النبوي (ال חג)', 'desc': 'احتفال المولد النبوي'},
    ],
    'رجب': [
      {'day': 27, 'title': 'الإسراء والمعراج', 'desc': 'ليلة الإسراء والمعراج'},
    ],
    'شعبان': [
      {'day': 15, 'title': 'ليلة النصف من شعبان', 'desc': 'ليلة مباركة'},
    ],
    'رمضان': [
      {'day': 1, 'title': 'بداية رمضان', 'desc': 'شهر الصيام'},
      {'day': 27, 'title': 'ليلة القدر', 'desc': 'خير من ألف شهر'},
    ],
    'شوال': [
      {'day': 1, 'title': 'عيد الفطر', 'desc': 'عيد الفطر المبارك'},
    ],
    'ذو الحجة': [
      {'day': 9, 'title': 'يوم عرفة', 'desc': 'يوم عرفة'},
      {'day': 10, 'title': 'عيد الأضحى', 'desc': 'عيد الأضحى المبارك'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _currentMonth = HijriCalendar.now();
  }

  int _daysInMonth(int month, int year) {
    if (month % 2 == 1) return 30;
    if (month < 12) return 29;
    return _isLeapYear(year) ? 30 : 29;
  }

  bool _isLeapYear(int year) {
    return ((11 * year + 14) % 30) < 11;
  }

  void _prevMonth() {
    setState(() {
      if (_currentMonth.hMonth == 1) {
        _currentMonth = HijriCalendar(hDay: 1, hMonth: 12, hYear: _currentMonth.hYear - 1);
      } else {
        _currentMonth = HijriCalendar(hDay: 1, hMonth: _currentMonth.hMonth - 1, hYear: _currentMonth.hYear);
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth.hMonth == 12) {
        _currentMonth = HijriCalendar(hDay: 1, hMonth: 1, hYear: _currentMonth.hYear + 1);
      } else {
        _currentMonth = HijriCalendar(hDay: 1, hMonth: _currentMonth.hMonth + 1, hYear: _currentMonth.hYear);
      }
    });
  }

  void _goToToday() {
    setState(() => _currentMonth = HijriCalendar.now());
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _monthNames[_currentMonth.hMonth];
    final days = _daysInMonth(_currentMonth.hMonth, _currentMonth.hYear);
    final firstDayWeekday = HijriCalendar()
      ..hDay = 1
      ..hMonth = _currentMonth.hMonth
      ..hYear = _currentMonth.hYear;

    int startWeekday = 6;
    try {
      final gregDate = HijriCalendar(
        hDay: 1,
        hMonth: _currentMonth.hMonth,
        hYear: _currentMonth.hYear,
      ).hijriToGregorian(
        _currentMonth.hYear,
        _currentMonth.hMonth,
        1,
      );
      startWeekday = gregDate.weekday % 7;
    } catch (_) {}

    final events = _islamicEvents[monthName] ?? [];

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
            _buildMonthHeader(monthName),
            const SizedBox(height: 12),
            _buildWeekdayHeader(),
            const SizedBox(height: 4),
            _buildCalendarGrid(days, startWeekday),
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
    final today = HijriCalendar.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('اليوم', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '${today.hDay} ${_monthNames[today.hMonth]} ${today.hYear}',
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

  Widget _buildMonthHeader(String monthName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _prevMonth,
        ),
        Column(
          children: [
            Text(
              monthName,
              style: const TextStyle(
                fontFamily: AppTheme.quranFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            Text(
              '${_currentMonth.hYear} هـ',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: _weekDays.map((d) => Expanded(
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
      )).toList(),
    );
  }

  Widget _buildCalendarGrid(int days, int startWeekday) {
    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int day = 1; day <= days; day++) {
      final isToday = day == _today.hDay &&
          _currentMonth.hMonth == _today.hMonth &&
          _currentMonth.hYear == _today.hYear;
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

  Widget _buildEventsSection(List<Map<String, dynamic>> events) {
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
              child: Text('${e['day']}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
            ),
            title: Text(e['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(e['desc'] as String),
          ),
        )),
      ],
    );
  }
}
