import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// تنزيل نسخة الكتاب من GitHub وحفظها على الجهاز.
/// المصدر: ملفات الكتب في مستودع التطبيق (raw.githubusercontent.com)
class BookDownloadService {
  static final BookDownloadService instance = BookDownloadService();
  final Map<String, String> _cachedPaths = {};

  Future<String?> download(String id, String url) async {
    if (_cachedPaths.containsKey(id)) return _cachedPaths[id];
    final dir = await getApplicationDocumentsDirectory();
    final bookDir = Directory('${dir.path}/books');
    if (!bookDir.existsSync()) bookDir.createSync(recursive: true);
    final file = File('${bookDir.path}/$id.json');
    if (file.existsSync()) {
      _cachedPaths[id] = file.path;
      return file.path;
    }
    final resp = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) {
      throw HttpException('HTTP ${resp.statusCode}', uri: Uri.parse(url));
    }
    await file.writeAsBytes(resp.bodyBytes, flush: true);
    _cachedPaths[id] = file.path;
    return file.path;
  }
}