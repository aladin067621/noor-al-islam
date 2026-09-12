import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quran_models.dart';
import '../utils/constants.dart';

/// خدمة تحميل النص القرآني وألوان التجويد والأجزاء من أصول محلية
/// (بيانات صادرة من Quran-Tajweed-Engine دون تعديل)
class QuranDataService {
  QuranDataService._();
  static final QuranDataService instance = QuranDataService._();

  final Map<int, QuranSurah> _surahCache = {};
  final Map<int, Map<int, List<TajweedSpan>>> _tajweedCache = {};
  List<QuranSurahMeta>? _metaCache;
  List<JuzInfo>? _juzCache;
  Map<String, String>? _ruleColors;

  Future<Map<String, dynamic>> _loadJson(String path) async {
    final raw = await rootBundle.loadString(path);
    return json.decode(raw) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _loadJsonList(String path) async {
    final raw = await rootBundle.loadString(path);
    return json.decode(raw) as List<dynamic>;
  }

  /// بيانات كل السور (بدون الآيات) — لقائمة السور
  Future<List<QuranSurahMeta>> loadSurahsMeta() async {
    if (_metaCache != null) return _metaCache!;
    final list = await _loadJsonList('${AppConstants.quranSurahsPath}/index.json');
    _metaCache =
        list.map((e) => QuranSurahMeta.fromJson(e as Map<String, dynamic>)).toList();
    return _metaCache!;
  }

  /// سورة كاملة بآياتها
  Future<QuranSurah> loadSurah(int id) async {
    if (_surahCache.containsKey(id)) return _surahCache[id]!;
    final data = await _loadJson(_surahPath(id));
    final surah = QuranSurah.fromJson(data);
    _surahCache[id] = surah;
    return surah;
  }

  /// خريطة رقم الآية ← قائمة ألوان التجويد (إزاحات UTF-16 في نص الآية)
  Future<Map<int, List<TajweedSpan>>> loadTajweed(int surahId) async {
    if (_tajweedCache.containsKey(surahId)) return _tajweedCache[surahId]!;
    final list = await _loadJsonList(_tajweedPath(surahId));
    final map = <int, List<TajweedSpan>>{};
    for (final e in list) {
      final ayah = (e as Map<String, dynamic>)['ayah'] as int;
      final anns = (e['annotations'] as List)
          .map((a) => TajweedSpan.fromJson(a as Map<String, dynamic>))
          .toList();
      map[ayah] = anns;
    }
    _tajweedCache[surahId] = map;
    return map;
  }

  /// قاعدة التجويد ← اللون الست عشري (من tajweed-rules.json)
  Future<Map<String, String>> loadRuleColors() async {
    if (_ruleColors != null) return _ruleColors!;
    final data = await _loadJson(AppConstants.quranRulesPath);
    final map = <String, String>{};
    for (final c in data['categories'] as List) {
      final cMap = c as Map<String, dynamic>;
      map[cMap['id'] as String] = cMap['colorHex'] as String;
    }
    _ruleColors = map;
    return map;
  }

  Map<String, dynamic>? _ruleCatalogCache;

  /// كتالوج أحكام التجويد كاملًا (الأقسام والأحكام وأوصافها وألوانها)
  /// — من tajweed-rules.json (Quran-Tajweed-Engine) دون تعديل.
  Future<Map<String, dynamic>> loadRulesCatalog() async {
    if (_ruleCatalogCache != null) return _ruleCatalogCache!;
    final data = await _loadJson(AppConstants.quranRulesPath);
    _ruleCatalogCache = data;
    return data;
  }

  /// قائمة الأجزاء الثلاثين
  Future<List<JuzInfo>> loadJuz() async {
    if (_juzCache != null) return _juzCache!;
    final list = await _loadJsonList(AppConstants.quranJuzPath);
    _juzCache =
        list.map((e) => JuzInfo.fromJson(e as Map<String, dynamic>)).toList();
    return _juzCache!;
  }

  String _surahPath(int id) =>
      '${AppConstants.quranSurahsPath}/${_pad3(id)}.json';
  String _tajweedPath(int id) =>
      '${AppConstants.quranTajweedPath}/${_pad3(id)}.json';

  static String _pad3(int n) => n.toString().padLeft(3, '0');
}