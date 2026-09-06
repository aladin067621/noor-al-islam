import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_models.dart';
import '../utils/constants.dart';

/// حالات الحفظ
/// 1 = متقن · 2 = مراجعة · 3 = قديم (يحتاج إعادة حفظ)
const int kStatusMemorized = 1;
const int kStatusReview = 2;
const int kStatusOld = 3;

/// إعدادات قسم حفظ القرآن (محلية)
class HifzSettings {
  String reciter;
  int repeatPerAyah;
  int delaySec;
  bool loopRange;
  bool tajweed;
  String script; // uthmani | indopak
  double mushafFontSize;
  int planDailyNew; // الهدف اليومي لآيات الحفظ الجديدة

  HifzSettings({
    this.reciter = AppConstants.defaultReciter,
    this.repeatPerAyah = 3,
    this.delaySec = 1,
    this.loopRange = false,
    this.tajweed = true,
    this.script = 'uthmani',
    this.mushafFontSize = 26,
    this.planDailyNew = 3,
  });

  factory HifzSettings.fromJson(Map<String, dynamic> j) => HifzSettings(
        reciter: j['reciter'] as String? ?? AppConstants.defaultReciter,
        repeatPerAyah: j['repeatPerAyah'] as int? ?? 3,
        delaySec: j['delaySec'] as int? ?? 1,
        loopRange: j['loopRange'] as bool? ?? false,
        tajweed: j['tajweed'] as bool? ?? true,
        script: j['script'] as String? ?? 'uthmani',
        mushafFontSize: (j['mushafFontSize'] as num?)?.toDouble() ?? 26,
        planDailyNew: j['planDailyNew'] as int? ?? 3,
      );

  Map<String, dynamic> toJson() => {
        'reciter': reciter,
        'repeatPerAyah': repeatPerAyah,
        'delaySec': delaySec,
        'loopRange': loopRange,
        'tajweed': tajweed,
        'script': script,
        'mushafFontSize': mushafFontSize,
        'planDailyNew': planDailyNew,
      };
}

/// يوم نشاط في سجل الجلسات
class HifzSession {
  String date;
  final List<String> newKeys;
  final List<Map<String, String>> reviews; // {key, rating}
  final List<String> tests;

  HifzSession({
    required this.date,
    List<String>? newKeys,
    List<Map<String, String>>? reviews,
    List<String>? tests,
  })  : newKeys = newKeys ?? [],
        reviews = reviews ?? [],
        tests = tests ?? [];

  factory HifzSession.fromJson(Map<String, dynamic> j) => HifzSession(
        date: j['date'] as String? ?? '',
        newKeys: (j['newKeys'] as List?)?.cast<String>() ?? [],
        reviews: ((j['reviews'] as List?) ?? [])
            .map((e) => (e as Map<String, dynamic>).cast<String, String>())
            .toList(),
        tests: (j['tests'] as List?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'newKeys': newKeys,
        'reviews': reviews,
        'tests': tests,
      };
}

/// تسجيل حالة الحفظ والمراجعة والجلسات — تخزين محلي فقط.
class HifzService extends ChangeNotifier {
  HifzService._();

  static final HifzService instance = HifzService._();

  final Map<String, int> _status = {};
  // بيانات المراجعة المتباعدة لكل آية: stage (عدد المرات الناجحة) + nextDue + memDate
  final Map<String, Map<String, dynamic>> _meta = {};
  List<HifzSession> _sessions = [];
  HifzSettings settings = HifzSettings();
  bool loaded = false;

  // فترات المراجعة بالأيام بعد الحفظ: اليوم 1 ثم 3 ثم 7 ثم 14 ثم 30.
  // بعد إتمام المرحلة الخامسة تُحسب الآية "متقنة" وتُجدول مراجعة شهرية دورية.
  static const List<int> reviewIntervals = [1, 3, 7, 14, 30];
  static const int kMasterStage = 5;

  Future<void> load() async {
    if (loaded) return;
    final prefs = await SharedPreferences.getInstance();

    final statusRaw = prefs.getString(AppConstants.keyHifzStatus);
    if (statusRaw != null) {
      try {
        final m = json.decode(statusRaw) as Map<String, dynamic>;
        m.forEach((k, v) => _status[k] = v as int);
      } catch (_) {}
    }

    final sessionsRaw = prefs.getString(AppConstants.keyHifzSessions);
    if (sessionsRaw != null) {
      try {
        _sessions = (json.decode(sessionsRaw) as List)
            .map((e) => HifzSession.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final settingsRaw = prefs.getString(AppConstants.keyHifzSettings);
    settings = settingsRaw != null
        ? HifzSettings.fromJson(json.decode(settingsRaw) as Map<String, dynamic>)
        : HifzSettings();

    final metaRaw = prefs.getString(AppConstants.keyHifzMeta);
    if (metaRaw != null) {
      try {
        final m = json.decode(metaRaw) as Map<String, dynamic>;
        m.forEach((k, v) => _meta[k] = (v as Map<String, dynamic>).cast());
      } catch (_) {}
    }
    loaded = true;
  }

  Future<void> _saveStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyHifzStatus, json.encode(_status));
    notifyListeners();
  }

  Future<void> _saveMeta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyHifzMeta, json.encode(_meta));
    notifyListeners();
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.keyHifzSessions,
        json.encode(_sessions.map((e) => e.toJson()).toList()));
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyHifzSettings, json.encode(settings.toJson()));
    notifyListeners();
  }

  static String _key(QuranPos p) => p.key;
  static String _keyOf(int s, int a) => '$s:$a';

  int? statusOf(QuranPos p) => _status[_key(p)];
  int? statusOf7(int s, int a) => _status[_keyOf(s, a)];

  bool hasStatus(QuranPos p) => _status.containsKey(_key(p));

  /// تسجيل آية جديدة للحفظ: تُسجَّل "قيد المراجعة" وتبدأ المراجعات المتباعدة.
  /// لا تُحسب متقنة بضغطة واحدة — الإتقان بعد إتمام مراحل المراجعات (kMasterStage).
  Future<void> markMemorized(List<QuranPos> pos) async {
    final today = _todayStr();
    for (final p in pos) {
      final key = _key(p);
      final cur = _meta[key];
      final curStage = (cur?['stage'] as int?) ?? 0;
      _meta[key] = {
        'stage': curStage < 0
            ? 0
            : (curStage > kMasterStage ? kMasterStage : curStage),
        'nextDue': today,
        'mem': cur?['mem'] ?? today,
      };
      if (_status[key] != kStatusMemorized) {
        _status[key] = kStatusReview;
      }
    }
    todaySession().newKeys.addAll(pos.map(_key).where((k) => !todaySession().newKeys.contains(k)));
    await _saveMeta();
    await _saveStatus();
    await _saveSessions();
  }

  Future<void> markMemorizedKey(int surah, int ayah) async {
    await markMemorized([QuranPos(surah, ayah)]);
  }

  /// مراجعة آية وتحديث مرحلتها وفق التقييم:
  /// منسي -> إعادة (المرحلة صفر) · صعبة -> لا تقدم · جيدة -> تقدم · سهلة -> تقدم مرتين.
  Future<void> markReview(QuranPos p, String rating) async {
    final key = _key(p);
    final today = _todayStr();
    var stage = (_meta[key]?['stage'] as int?) ?? 0;
    switch (rating) {
      case 'forgot':
        stage = 0;
        break;
      case 'hard':
        break;
      case 'easy':
        stage += 2;
        break;
      default: // good
        stage += 1;
    }
    if (stage >= kMasterStage) {
      _meta[key] = {'stage': kMasterStage, 'nextDue': _daysFromToday(30), 'mem': _meta[key]?['mem'] ?? today};
      _status[key] = kStatusMemorized;
    } else {
      final days = _intervalFor(stage);
      _meta[key] = {'stage': stage, 'nextDue': _daysFromToday(days), 'mem': _meta[key]?['mem'] ?? today};
      _status[key] = rating == 'forgot' ? kStatusOld : kStatusReview;
    }
    todaySession().reviews.add({'key': key, 'rating': rating});
    await _saveMeta();
    await _saveStatus();
    await _saveSessions();
  }

  /// تسجيل تسميع ناجح لآية (زر "أسمعتُها") — يُحتسب تقدمًا في المراجعة كتقييم "جيدة".
  Future<void> markTested(QuranPos p) async {
    final key = _key(p);
    final today = _todayStr();
    var stage = (_meta[key]?['stage'] as int?) ?? 0;
    if (stage < kMasterStage) stage += 1;
    if (stage >= kMasterStage) {
      _meta[key] = {'stage': kMasterStage, 'nextDue': _daysFromToday(30), 'mem': _meta[key]?['mem'] ?? today};
      _status[key] = kStatusMemorized;
    } else {
      final days = _intervalFor(stage);
      _meta[key] = {'stage': stage, 'nextDue': _daysFromToday(days), 'mem': _meta[key]?['mem'] ?? today};
      _status[key] = kStatusReview;
    }
    if (!todaySession().tests.contains(key)) {
      todaySession().tests.add(key);
    }
    await _saveMeta();
    await _saveStatus();
    await _saveSessions();
  }

  /// إزالة تسجيل آية (إعادة اعتبارها جديدة)
  Future<void> clearStatus(QuranPos p) async {
    final key = _key(p);
    _status.remove(key);
    _meta.remove(key);
    await _saveStatus();
    await _saveMeta();
  }

  // ==================== بيانات المراجعة المتباعدة ====================

  static String _daysFromToday(int days) {
    final d = DateTime.now().add(Duration(days: days));
    String two(int x) => x.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static int _intervalFor(int stage) {
    final idx = stage < 0
        ? 0
        : (stage >= reviewIntervals.length ? reviewIntervals.length - 1 : stage);
    return reviewIntervals[idx] ?? 1;
  }

  /// مرحلة المراجعة الحالية للآية (0..kMasterStage)
  int stageOf(QuranPos p, {int surah = 0, int ayah = 0}) {
    final key = surah > 0 ? _keyOf(surah, ayah) : _key(p);
    return (_meta[key]?['stage'] as int?) ?? 0;
  }

  bool isMemorized(QuranPos p) => stageOf(p) >= kMasterStage;

  /// تاريخ استحقاق المراجعة القادمة (yyyy-MM-dd) أو null إن لم تُسجَّل
  String? nextDueOf(QuranPos p) => _meta[_key(p)]?['nextDue'] as String?;

  /// عدد آيات مستحقة المراجعة اليوم
  int todayDueCount() => dueList().length;

  /// آيات مستحقة المراجعة اليوم (مُسجّلة ولها استحقاق ≤ اليوم)
  List<QuranPos> dueList() {
    final today = _todayStr();
    final out = <QuranPos>[];
    _meta.forEach((k, v) {
      final due = v['nextDue'] as String?;
      if (due != null && due.compareTo(today) <= 0) {
        final parts = k.split(':');
        if (parts.length == 2) {
          out.add(QuranPos(int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0));
        }
      }
    });
    out.sort((a, b) {
      final c = a.surah.compareTo(b.surah);
      return c != 0 ? c : a.ayah.compareTo(b.ayah);
    });
    return out;
  }

  HifzSession todaySession() {
    final today = _todayStr();
    for (final s in _sessions) {
      if (s.date == today) return s;
    }
    final ns = HifzSession(date: today);
    _sessions.add(ns);
    return ns;
  }

  static String _todayStr() {
    final d = DateTime.now();
    String two(int x) => x.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  int get totalMemorized =>
      _status.values.where((v) => v == kStatusMemorized).length;

  int get totalReview =>
      _status.values.where((v) => v == kStatusReview).length;

  List<QuranPos> memorizedPositions() {
    final out = <QuranPos>[];
    _status.forEach((k, v) {
      if (v == kStatusMemorized) {
        final parts = k.split(':');
        if (parts.length == 2) {
          out.add(QuranPos(int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0));
        }
      }
    });
    return out;
  }

  List<QuranPos> positionsOf(int surahId) {
    final out = <QuranPos>[];
    _status.forEach((k, v) {
      final parts = k.split(':');
      if (parts.length == 2 && int.tryParse(parts[0]) == surahId) {
        out.add(QuranPos(surahId, int.tryParse(parts[1]) ?? 0));
      }
    });
    return out;
  }

  int memCountOfSurah(int surahId) => _status.entries
      .where((e) => e.value == kStatusMemorized && e.key.startsWith('$surahId:'))
      .length;

  int _todayField(Function(HifzSession) sel) {
    for (final s in _sessions) {
      if (s.date == _todayStr()) return sel(s);
    }
    return 0;
  }

  int get todayNew => _todayField((s) => s.newKeys.length);
  int get todayReviews => _todayField((s) => s.reviews.length);
  int get todayTests => _todayField((s) => s.tests.length);
  /// الهدف اليومي لآيات الحفظ الجديدة من الإعدادات
  int get dailyNewGoal => settings.planDailyNew;

  /// سلسلة الأيام المتتالية للنشاط (حتى اليوم أو أمس)
  int get streak {
    final days = _sessions.map((s) => s.date).toSet();
    var count = 0;
    var d = DateTime.now();
    if (!days.contains(_fmt(d))) {
      d = d.subtract(const Duration(days: 1));
      if (!days.contains(_fmt(d))) return 0;
    }
    while (days.contains(_fmt(d))) {
      count++;
      d = d.subtract(const Duration(days: 1));
    }
    return count;
  }

  String _fmt(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// أعداد النشاط آخر 7 أيام [{date, yyyy-MM-dd، count, aktiv}]
  List<Map<String, dynamic>> last7Days() {
    final counts = <String, int>{};
    for (final s in _sessions) {
      final c = s.newKeys.length + s.reviews.length + s.tests.length;
      counts[s.date] = c;
    }
    final out = <Map<String, dynamic>>[];
    for (var i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final f = _fmt(d);
      out.add({'date': f, 'count': counts[f] ?? 0});
    }
    return out;
  }
}