import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/quran_models.dart';
import '../services/hifz_service.dart';
import '../utils/constants.dart';

/// خدمة التلاوة من alquran.cloud — بث/تنزيل الآية مرّة واحدة ثم تشغيلها محليًا،
/// مع دعم التكرار (لأغراض الحفظ) دون أي استخدام للميكروفون.
class QuranAudioService extends ChangeNotifier {
  QuranAudioService._() : _player = AudioPlayer() {
    _player.onPlayerComplete.listen((_) => _onPlayerComplete());
  }

  static final QuranAudioService instance = QuranAudioService._();

  final AudioPlayer _player;
  String _reciter = AppConstants.defaultReciter;
  QuranPos? _current;
  QuranPos? _rangeStart;
  QuranPos? _rangeEnd;
  bool _playing = false;
  bool _downloading = false;
  String? _lastError;
  int _sameCount = 0;
  int _generation = 0;
  final Set<String> _cached = {};
  Directory? _docsDir;

  HifzSettings get _cfg => HifzService.instance.settings;

  /// التكرار لكل آية من الإعدادات
  int get repeatPerAyah => _cfg.repeatPerAyah;
  int get delaySec => _cfg.delaySec;
  bool get loopRange => _cfg.loopRange;

  String get reciter => _reciter;
  QuranPos? get current => _current;
  QuranPos? get rangeStart => _rangeStart;
  QuranPos? get rangeEnd => _rangeEnd;
  bool get playing => _playing;
  bool get downloading => _downloading;
  String? get errorMessage => _lastError;

  Future<void> init() async {
    if (_docsDir != null) return;
    _docsDir = await getApplicationDocumentsDirectory();
    await _reloadCacheKeys();
  }

  Future<void> setReciter(String r) async {
    if (_reciter == r) return;
    _stop();
    _reciter = r;
    _cfg.reciter = r;
    await HifzService.instance.saveSettings();
    _cached.clear();
    await _reloadCacheKeys();
    notifyListeners();
  }

  Future<void> _reloadCacheKeys() async {
    final dir = Directory(_cacheDirPath());
    _cached.clear();
    try {
      if (await dir.exists()) {
        await for (final e in dir.list()) {
          final name = e.path.split(Platform.pathSeparator).last;
          final m = RegExp(r'^(\d+)_(\d+)\.mp3$').firstMatch(name);
          if (m != null) _cached.add('${m.group(1)}:${m.group(2)}');
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  String _cacheDirPath() =>
      '${_docsDir?.path}/quran_audio/$_reciter';

  /// الرقم الشامل للآية (1-6236) كما تعتمده شبكة التوزيع في روابط الصوت،
  /// حيث تُخدَّم الآيات بالرقم التسلسلي العالمي لا بمسار سورة/آية.
  static const List<int> _firstGlobalAyahOfSurah = [
    1, 8, 294, 494, 670, 790, 955, 1161, 1236, 1365,
    1474, 1597, 1708, 1751, 1803, 1902, 2030, 2141, 2251, 2349,
    2484, 2596, 2674, 2792, 2856, 2933, 3160, 3253, 3341, 3410,
    3470, 3504, 3534, 3607, 3661, 3706, 3789, 3971, 4059, 4134,
    4219, 4273, 4326, 4415, 4474, 4511, 4546, 4584, 4613, 4631,
    4676, 4736, 4785, 4847, 4902, 4980, 5076, 5105, 5127, 5151,
    5164, 5178, 5189, 5200, 5218, 5230, 5242, 5272, 5324, 5376,
    5420, 5448, 5476, 5496, 5552, 5592, 5623, 5673, 5713, 5759,
    5801, 5830, 5849, 5885, 5910, 5932, 5949, 5968, 5994, 6024,
    6044, 6059, 6080, 6091, 6099, 6107, 6126, 6131, 6139, 6147,
    6158, 6169, 6177, 6180, 6189, 6194, 6198, 6205, 6208, 6214,
    6217, 6222, 6226, 6231,
  ];

  /// رقم الآية التسلسلي العالمي (1-6236).
  static int globalAyahOf(int surah, int ayah) {
    if (surah < 1 || surah > _firstGlobalAyahOfSurah.length) return 0;
    return _firstGlobalAyahOfSurah[surah - 1] + ayah - 1;
  }

  String urlOf(int surah, int ayah) =>
      '${AppConstants.quranAudioBase}/$_reciter/${globalAyahOf(surah, ayah)}.mp3';

  bool isCached(int surah, int ayah) => _cached.contains('$surah:$ayah');

  /// تشغيل آية واحدة مع التكرار المحدد في الإعدادات
  Future<void> playAyah(QuranPos pos) async {
    _rangeStart = pos;
    _rangeEnd = pos;
    _current = pos;
    _sameCount = 0;
    await _playCurrent();
  }

  /// تشغيل نطاق آيات (جلسة حفظ/استماع) مع تكرار كل آية
  Future<void> playRange(QuranPos start, QuranPos end) async {
    _rangeStart = start;
    _rangeEnd = end;
    _current = start;
    _sameCount = 0;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final pos = _current;
    if (pos == null) return;
    _generation++;
    final gen = _generation;
    _playing = true;
    _downloading = !isCached(pos.surah, pos.ayah);
    _sameCount = 0;
    notifyListeners();

    String path;
    if (isCached(pos.surah, pos.ayah)) {
      path = await _cachedPath(pos.surah, pos.ayah);
    } else {
      final ok = await _download(pos.surah, pos.ayah);
      if (gen != _generation) return;
      if (!ok) {
        // فشل التحميل: نصفي حالة "جارِ التحميل" ونعرض خطأً واضحًا بدلًا من البقاء عالقًا
        _downloading = false;
        _playing = false;
        _lastError = 'تعذر تحميل تلاوة هذه الآية — تأكد من اتصالك بالإنترنت ثم أعد المحاولة';
        notifyListeners();
        return;
      }
      path = await _cachedPath(pos.surah, pos.ayah);
    }
    if (gen != _generation) return;
    _downloading = false;
    _lastError = null;
    notifyListeners();
    try {
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      _downloading = false;
      _playing = false;
      _lastError = 'تعذر تشغيل التلاوة على هذا الجهاز';
      notifyListeners();
    }
  }

  Future<String> _cachedPath(int surah, int ayah) async {
    await _ensureReciterDir();
    return '${_cacheDirPath()}/$surah\_$ayah.mp3';
  }

  /// عناوين تشبه المتصفح: بعض شبكات التوزيع ترفض الطلبات الآلية.
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
    'Accept': '*/*',
  };

  Future<bool> _download(int surah, int ayah) async {
    if (surah < 1) return false;
    try {
      await _ensureReciterDir();
      final path = await _cachedPath(surah, ayah);
      final global = globalAyahOf(surah, ayah);
      final urls = <String>[
        '${AppConstants.quranAudioBase}/$_reciter/$global.mp3',
        '${AppConstants.quranAudioBaseSecondary}/$_reciter/$global.mp3',
        '${AppConstants.quranAudioBaseTertiary}/$_reciter/$global',
      ];
      http.Response? resp;
      Object? lastErr;
      for (final u in urls) {
        try {
          resp = await http
              .get(Uri.parse(u), headers: _headers)
              .timeout(const Duration(seconds: 40));
          if (resp.statusCode == 200) break;
          resp = null;
        } catch (e) {
          lastErr = e;
        }
      }
      if (resp == null) {
        if (lastErr != null) throw lastErr;
        return false;
      }
      final file = File(path);
      await file.writeAsBytes(resp.bodyBytes, flush: true);
      _cached.add('$surah:$ayah');
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _ensureReciterDir() async {
    final dir = Directory(_cacheDirPath());
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  void _onPlayerComplete() {
    final pos = _current;
    if (pos == null) return;
    final gen = ++_generation;

    Future<void> afterDelay(Future<void> Function() action) async {
      await Future.delayed(Duration(seconds: delaySec));
      if (gen != _generation) return;
      await action();
    }

    // تكرار نفس الآية
    if (repeatPerAyah > 1 && _sameCount < repeatPerAyah - 1) {
      _sameCount++;
      afterDelay(() async {
        if (gen != _generation || _current == null) return;
        await _replayCurrent();
      });
      return;
    }

    final next = _nextInRange();
    if (next != null) {
      afterDelay(() async {
        if (gen != _generation) return;
        _current = next;
        await _playCurrent();
      });
      return;
    }

    // نهاية النطاق
    if (loopRange && _rangeStart != null) {
      afterDelay(() async {
        if (gen != _generation) return;
        _current = _rangeStart;
        await _playCurrent();
      });
      return;
    }
    _playing = false;
    notifyListeners();
  }

  Future<void> _replayCurrent() async {
    final pos = _current;
    if (pos == null) return;
    final cached = isCached(pos.surah, pos.ayah);
    if (cached) {
      await _player.play(DeviceFileSource(await _cachedPath(pos.surah, pos.ayah)));
    } else {
      await _playCurrent();
    }
  }

  QuranPos? _nextInRange() {
    final cur = _current;
    final end = _rangeEnd;
    if (cur == null || end == null) return null;
    final ny = cur.ayah + 1;
    final next = QuranPos(cur.surah, ny);
    if (next.surah == end.surah && ny > end.ayah) return null;
    // عبور لنهاية السورة الحالية (بلا معرفة بعدّاد السورة التالية،
    // يكفي الرجوع إلى أول آية من السورة التالية ونطاق الحفظ عادة داخل سورة).
    return QuranPos(cur.surah, ny);
  }

  Future<void> pause() async {
    _generation++;
    await _player.pause();
    _playing = false;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_current == null) return;
    if (!_playing) {
      await _player.resume();
      _playing = true;
      notifyListeners();
    }
  }

  Future<void> next() async {
    _generation++;
    final next = _nextInRange();
    if (next == null) return;
    _current = next;
    await _playCurrent();
  }

  Future<void> prev() async {
    final cur = _current;
    if (cur == null) return;
    _generation++;
    if (cur.ayah > 1) {
      _current = QuranPos(cur.surah, cur.ayah - 1);
    } else if (cur.surah > 1) {
      _current = QuranPos(cur.surah - 1, 1);
    }
    await _playCurrent();
  }

  void _stop() {
    _generation++;
    _playing = false;
    _downloading = false;
    _lastError = null;
    _player.stop();
  }

  Future<void> stop() async {
    _stop();
    _current = null;
    _rangeStart = null;
    _rangeEnd = null;
    notifyListeners();
  }

  /// عدد الآيات المخزّنة محليًا
  int get cachedCount => _cached.length;
}