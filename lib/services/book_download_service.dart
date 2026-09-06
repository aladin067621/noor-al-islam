import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chapter.dart';

/// حفظ نسخ الكتب على الجهاز (نصيًا أو PDF) مع حالة محفوظة دائمة.
class BookDownloadService {
  BookDownloadService._();
  static final BookDownloadService instance = BookDownloadService();

  static const _savedBooksKey = 'saved_books_v1';
  static const _savedPdfKey = 'saved_pdf_v1';

  final Map<String, String> _cachedPaths = {};

  Future<Directory> _dir(String sub) async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory('${dir.path}/$sub');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  Future<Directory> _booksDir() => _dir('books');
  Future<Directory> _pdfsDir() => _dir('pdfs');

  Future<Set<String>> _loadIds(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? []).toSet();
  }

  Future<void> _saveIds(String key, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, ids.toList());
  }

  Future<void> _mark(String key, String id, bool saved) async {
    final ids = await _loadIds(key);
    if (saved) {
      if (ids.add(id)) await _saveIds(key, ids);
    } else if (ids.remove(id)) {
      await _saveIds(key, ids);
    }
  }

  // ==================== كتب الفصول (نسخة نصية JSON) ====================

  /// حفظ نسخة نصية من الكتاب وتثبيت حالة «محفوظ» بشكل دائم.
  Future<String?> downloadJson(String id, List<Chapter> chapters) async {
    if (_cachedPaths.containsKey(id)) return _cachedPaths[id];
    final dir = await _booksDir();
    final file = File('${dir.path}/$id.json');
    if (file.existsSync()) {
      _cachedPaths[id] = file.path;
      await _mark(_savedBooksKey, id, true);
      return file.path;
    }
    final data = chapters
        .map((c) => {'title': c.title, 'content': c.content})
        .toList();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data),
        flush: true);
    _cachedPaths[id] = file.path;
    await _mark(_savedBooksKey, id, true);
    return file.path;
  }

  /// مسار النسخة المحفوظة من الكتاب، أو null إن لم توجد.
  Future<String?> bookFilePath(String id) async {
    if (_cachedPaths.containsKey(id)) return _cachedPaths[id];
    final file = File('${(await _booksDir()).path}/$id.json');
    if (file.existsSync()) {
      _cachedPaths[id] = file.path;
      return file.path;
    }
    return null;
  }

  Future<bool> isBookSaved(String id) async {
    final ids = await _loadIds(_savedBooksKey);
    if (!ids.contains(id)) return false;
    return await bookFilePath(id) != null;
  }

  Future<void> deleteBook(String id) async {
    final path = await bookFilePath(id);
    if (path != null) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    _cachedPaths.remove(id);
    await _mark(_savedBooksKey, id, false);
  }

  // ==================== ملفات PDF (محفوظة محليًا) ====================

  /// تنزيل ملف PDF وحفظه محليًا إن لم يكن موجودًا مسبقًا.
  Future<String?> ensurePdf(String id, String url) async {
    final existing = await pdfFilePath(id);
    if (existing != null) return existing;
    final dir = await _pdfsDir();
    final file = File('${dir.path}/$id.pdf');
    try {
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 90));
      if (resp.statusCode != 200) return null;
      await file.writeAsBytes(resp.bodyBytes, flush: true);
    } catch (_) {
      return null;
    }
    _cachedPaths[id] = file.path;
    await _mark(_savedPdfKey, id, true);
    return file.path;
  }

  Future<String?> pdfFilePath(String id) async {
    if (_cachedPaths.containsKey(id)) return _cachedPaths[id];
    final file = File('${(await _pdfsDir()).path}/$id.pdf');
    if (file.existsSync()) {
      _cachedPaths[id] = file.path;
      return file.path;
    }
    return null;
  }

  Future<bool> isPdfSaved(String id) async {
    final ids = await _loadIds(_savedPdfKey);
    if (!ids.contains(id)) return false;
    return await pdfFilePath(id) != null;
  }

  Future<void> deletePdf(String id) async {
    final path = await pdfFilePath(id);
    if (path != null) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    _cachedPaths.remove(id);
    await _mark(_savedPdfKey, id, false);
  }
}