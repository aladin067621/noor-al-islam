import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/dhikr.dart';
import '../models/adhkar_category.dart';
import '../models/prayer_step.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../utils/constants.dart';

/// خدمة تحميل المحتوى المحلي من ملفات JSON في assets
class DataService {
  DataService._();
  static final DataService instance = DataService._();

  // ذاكرة تخزين مؤقت
  final Map<String, List<Dhikr>> _adhkarCache = {};
  List<Dhikr>? _hisnAdhkar;
  List<Dhikr>? _wabilAdhkar;
  List<PrayerTab>? _prayerTabs;
  List<dynamic>? _tawheedSections;
  Map<String, dynamic>? _pillars;
  List<Book>? _booksIndex;
  final Map<String, List<Chapter>> _chaptersCache = {};
  List<dynamic>? _tafsirSurahs;
  Map<String, dynamic>? _config;

  Future<Map<String, dynamic>> _loadJson(String path) async {
    final raw = await rootBundle.loadString(path);
    return json.decode(raw) as Map<String, dynamic>;
  }

  /// تحميل أذكار فئة معيّنة
  Future<List<Dhikr>> loadAdhkar(String key) async {
    if (_adhkarCache.containsKey(key)) return _adhkarCache[key]!;
    final path = AppConstants.adhkarFiles[key]!;
    final data = await _loadJson(path);
    final category = data['category'] ?? key;
    final items = (data['items'] as List)
        .map((e) => Dhikr.fromJson(e as Map<String, dynamic>, category))
        .toList();
    _adhkarCache[key] = items;
    return items;
  }

  /// عنوان فئة أذكار
  Future<String> adhkarTitle(String key) async {
    final data = await _loadJson(AppConstants.adhkarFiles[key]!);
    return data['title'] ?? key;
  }

  /// فئات حصن المسلم (مع عناصرها) — تُستخدم في شاشة "أذكار أخرى"
  Future<List<AdhkarCategory>> loadHisnCategories() async {
    final data = await _loadJson(AppConstants.hisnAdhkarPath);
    return (data['categories'] as List)
        .map((c) =>
            AdhkarCategory.fromJson(c as Map<String, dynamic>, book: 'حصن المسلم'))
        .toList();
  }

  /// فئات الوابل الصيب (مع عناصرها) — تُستخدم في شاشة "أذكار أخرى"
  Future<List<AdhkarCategory>> loadWabilCategories() async {
    final data = await _loadJson(AppConstants.wabilAdhkarPath);
    return (data['categories'] as List)
        .map((c) => AdhkarCategory.fromJson(
            c as Map<String, dynamic>,
            book: 'الوابل الصيب'))
        .toList();
  }

  /// كل فئات حصن المسلم والوابل الصيب مصغرة (بدون عناصر) — للتعرف على المفاتيح
  Future<Map<String, AdhkarCategory>> loadHisnWabilCategoriesByKey() async {
    final map = <String, AdhkarCategory>{};
    for (final c in await loadHisnCategories()) {
      map[c.uniqueKey] = c;
    }
    for (final c in await loadWabilCategories()) {
      map[c.uniqueKey] = c;
    }
    return map;
  }

  /// كل الأذكار (لكل الفئات) — للبحث والمفضلة
  Future<List<Dhikr>> loadAllAdhkar() async {
    final all = <Dhikr>[];
    for (final key in AppConstants.adhkarFiles.keys) {
      all.addAll(await loadAdhkar(key));
    }
    all.addAll(await loadHisnAdhkar());
    all.addAll(await loadWabilAdhkar());
    return all;
  }

  /// تحميل جميع أبواب حصن المسلم من ملف محلي موثق المصدر.
  Future<List<Dhikr>> loadHisnAdhkar() async {
    if (_hisnAdhkar != null) return _hisnAdhkar!;
    final data = await _loadJson(AppConstants.hisnAdhkarPath);
    final result = <Dhikr>[];
    for (final category in data['categories'] as List) {
      final categoryData = category as Map<String, dynamic>;
      final title = categoryData['title']?.toString() ?? 'حصن المسلم';
      for (final item in categoryData['items'] as List) {
        result.add(Dhikr.fromJson(item as Map<String, dynamic>, title));
      }
    }
    _hisnAdhkar = result;
    return result;
  }

  /// تحميل جميع أذكار الوابل الصيب من ملف محلي موثق المصدر.
  Future<List<Dhikr>> loadWabilAdhkar() async {
    if (_wabilAdhkar != null) return _wabilAdhkar!;
    final data = await _loadJson(AppConstants.wabilAdhkarPath);
    final result = <Dhikr>[];
    for (final category in data['categories'] as List) {
      final categoryData = category as Map<String, dynamic>;
      final title = categoryData['title']?.toString() ?? 'الوابل الصيب';
      for (final item in categoryData['items'] as List) {
        result.add(Dhikr.fromJson(item as Map<String, dynamic>, title));
      }
    }
    _wabilAdhkar = result;
    return result;
  }

  Future<List<PrayerTab>> loadPrayerTabs() async {
    if (_prayerTabs != null) return _prayerTabs!;
    final data = await _loadJson(AppConstants.prayerStepsFile);
    _prayerTabs = (data['tabs'] as List)
        .map((e) => PrayerTab.fromJson(e as Map<String, dynamic>))
        .toList();
    return _prayerTabs!;
  }

  Future<List<dynamic>> loadTawheedSections() async {
    if (_tawheedSections != null) return _tawheedSections!;
    final data = await _loadJson(AppConstants.tawheedFile);
    _tawheedSections = data['sections'] as List;
    return _tawheedSections!;
  }

  Future<Map<String, dynamic>> loadPillars() async {
    if (_pillars != null) return _pillars!;
    _pillars = await _loadJson(AppConstants.pillarsFile);
    return _pillars!;
  }

  Future<List<Book>> loadBooksIndex() async {
    if (_booksIndex != null) return _booksIndex!;
    final data = await _loadJson(AppConstants.booksIndexFile);
    _booksIndex = (data['books'] as List)
        .map((e) => Book.fromIndexJson(e as Map<String, dynamic>))
        .toList();
    return _booksIndex!;
  }

  Future<List<Chapter>> loadChapters(Book book) async {
    if (_chaptersCache.containsKey(book.id)) return _chaptersCache[book.id]!;
    final data = await _loadJson(book.assetFile);
    final chapters = (data['chapters'] as List)
        .map((e) => Chapter.fromJson(e as Map<String, dynamic>, book.id, book.title))
        .toList();
    _chaptersCache[book.id] = chapters;
    return chapters;
  }

  Future<List<dynamic>> loadTafsirSurahs() async {
    if (_tafsirSurahs != null) return _tafsirSurahs!;
    final data = await _loadJson(AppConstants.tafsirFile);
    _tafsirSurahs = data['surahs'] as List;
    return _tafsirSurahs!;
  }

  Future<Map<String, dynamic>> loadConfig() async {
    if (_config != null) return _config!;
    _config = await _loadJson(AppConstants.configPath);
    return _config!;
  }

  Future<String> loadReferences() async {
    return rootBundle.loadString(AppConstants.referencesPath);
  }
}
