import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/chapter.dart';

/// حفظ نسخة من الكتاب كملف JSON على الجهاز للقراءة خارج التطبيق.
class BookDownloadService {
  static final BookDownloadService instance = BookDownloadService();
  final Map<String, String> _cachedPaths = {};

  Future<String?> download(String id, List<Chapter> chapters) async {
    if (_cachedPaths.containsKey(id)) return _cachedPaths[id];
    final dir = await getApplicationDocumentsDirectory();
    final bookDir = Directory('${dir.path}/books');
    if (!bookDir.existsSync()) bookDir.createSync(recursive: true);
    final file = File('${bookDir.path}/$id.json');
    if (file.existsSync()) {
      _cachedPaths[id] = file.path;
      return file.path;
    }
    final data = chapters
        .map((c) => {'title': c.title, 'content': c.content})
        .toList();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data),
        flush: true);
    _cachedPaths[id] = file.path;
    return file.path;
  }
}
