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
        .map((e) => Dhikr.fromJson(e as Map<String, dynamic>, category,
            sourceKey: key))
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
        .map((c) => AdhkarCategory.fromJson(c as Map<String, dynamic>,
            book: 'حصن المسلم', sourceKey: 'hisn'))
        .toList();
  }

  /// فئات الوابل الصيب (مع عناصرها) — تُستخدم في شاشة "أذكار أخرى"
  Future<List<AdhkarCategory>> loadWabilCategories() async {
    final data = await _loadJson(AppConstants.wabilAdhkarPath);
    return (data['categories'] as List)
        .map((c) => AdhkarCategory.fromJson(c as Map<String, dynamic>,
            book: 'الوابل الصيب', sourceKey: 'wabil'))
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
        result.add(Dhikr.fromJson(item as Map<String, dynamic>, title,
            sourceKey: 'hisn',
            categoryKey: categoryData['key']?.toString()));
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
        result.add(Dhikr.fromJson(item as Map<String, dynamic>, title,
            sourceKey: 'wabil',
            categoryKey: categoryData['key']?.toString()));
      }
    }
    _wabilAdhkar = result;
    return result;
  }

  // خريطة مرجعية: refKey -> Dhikr — لاسترجاع الأذكار من أي قائمة مراجع
  Map<String, Dhikr>? _adhkarByRef;

  Future<Map<String, Dhikr>> loadAllAdhkarByRefKey() async {
    if (_adhkarByRef != null) return _adhkarByRef!;
    final map = <String, Dhikr>{};
    for (final d in await loadAllAdhkar()) {
      map[d.refKey] = d;
    }
    _adhkarByRef = map;
    return map;
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
    final all = (data['books'] as List)
        .map((e) => Book.fromIndexJson(e as Map<String, dynamic>))
        .toList();

    // تجميع الأجزاء (nasaai_p0..p9، tirmidhi_p1..p5، abu_dawud_p1..p6) تحت أصل واحد
    final re = RegExp(r'^(.*)_p(\d+)$');
    final grouped = <String, List<Book>>{};
    final result = <Book>[];
    for (final b in all) {
      final m = re.firstMatch(b.id);
      if (m != null && b.downloadUrl.isNotEmpty) {
        grouped.putIfAbsent(m.group(1)!, () => []).add(b);
      } else {
        result.add(b);
      }
    }
    grouped.forEach((baseId, parts) {
      parts.sort((a, b) {
        final na = int.tryParse(re.firstMatch(a.id)?.group(2) ?? '0') ?? 0;
        final nb = int.tryParse(re.firstMatch(b.id)?.group(2) ?? '0') ?? 0;
        return na.compareTo(nb);
      });
      final firstTitle = parts.first.title;
      final baseTitle = firstTitle.contains(' — ')
          ? firstTitle.split(' — ').first.trim()
          : firstTitle;
      final parent = Book(
        id: baseId,
        title: baseTitle,
        author: parts.first.author,
        benefit: '${parts.length} أجزاء',
        intro: 'الكتاب مقسّم إلى أجزاء — اختر الجزء المطلوب.',
        reference: '',
        assetFile: '',
        volumeChildren: [
          for (final p in parts) p.copyWithVolumeLabel(_volumeLabelOf(p)),
        ],
      );
      result.add(parent);
    });

    _booksIndex = result;
    return _booksIndex!;
  }

  String _volumeLabelOf(Book b) {
    final i = b.title.indexOf(' — ');
    return i >= 0 ? b.title.substring(i + 3).trim() : b.title;
  }

  Future<List<Chapter>> loadChapters(Book book) async {
    if (_chaptersCache.containsKey(book.id)) return _chaptersCache[book.id]!;
    // كتب PDF والأجزاء المجمّعة لا تحتوي على ملف فصول
    if (book.assetFile.isEmpty || book.volumeChildren.isNotEmpty) {
      _chaptersCache[book.id] = const [];
      return const [];
    }
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
