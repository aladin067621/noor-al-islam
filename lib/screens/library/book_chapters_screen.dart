import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../services/data_service.dart';
import '../../services/book_download_service.dart';
import '../../utils/theme.dart';
import 'chapter_reader_screen.dart';

class BookChaptersScreen extends StatefulWidget {
  final Book book;
  const BookChaptersScreen({super.key, required this.book});

  @override
  State<BookChaptersScreen> createState() => _BookChaptersScreenState();
}

class _BookChaptersScreenState extends State<BookChaptersScreen> {
  bool _downloading = false;
  String? _downloadedPath;

  Book get book => widget.book;

  Future<void> _downloadBook() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final chapters = await DataService.instance.loadChapters(book);
      final path = await BookDownloadService.instance.download(book.id, chapters);
      if (!mounted) return;
      setState(() => _downloadedPath = path);
      _snack('تم حفظ النسخة كملف JSON على جهازك، يمكنك فتحها بأي تطبيق.');
    } catch (e) {
      if (!mounted) return;
      _snack('تعذر حفظ النسخة على جهازك');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: FutureBuilder<List<Chapter>>(
        future: DataService.instance.loadChapters(book),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chapters = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // مقدمة / نبذة عن المؤلف
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(book.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('المؤلف: ${book.author}',
                          style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(book.intro, style: const TextStyle(height: 1.8)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            if (chapters.isEmpty) {
                              _snack('لا توجد أقسام للقراءة في هذا الكتاب');
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChapterReaderScreen(chapter: chapters.first),
                              ),
                            );
                          },
                          icon: const Icon(Icons.auto_stories),
                          label: _downloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('اقرأ الكتاب الآن'),
                        ),
                      ),
                      if (book.assetFile.isNotEmpty)
                        TextButton.icon(
                          onPressed: _downloading ? null : _downloadBook,
                          icon: Icon(
                            _downloadedPath != null ? Icons.check_circle_outline : Icons.download,
                            size: 18,
                          ),
                          label: Text(_downloading
                              ? 'جارٍ الحفظ...'
                              : _downloadedPath != null
                                  ? 'تم حفظ نسخة على جهازك'
                                  : 'حفظ نسخة على جهازك (JSON)'),
                        ),
                      if (_downloadedPath != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'حُفظت في: $_downloadedPath',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'الكتاب متاح للقراءة داخل التطبيق مباشرة دون اتصال بالإنترنت.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text('أقسام الكتاب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ...chapters.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChapterReaderScreen(chapter: c)),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
