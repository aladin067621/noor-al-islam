import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../services/data_service.dart';
import '../../services/book_download_service.dart';
import '../../utils/theme.dart';
import 'book_reader_screen.dart';
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
  List<Chapter> _chapters = [];

  Book get book => widget.book;
  bool get _isPdfBook => book.downloadUrl.isNotEmpty;

  Future<void> _saveCopy() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final path = await BookDownloadService.instance.download(book.id, _chapters);
      if (!mounted) return;
      setState(() => _downloadedPath = path);
      _snack('تم حفظ نسخة الكتاب على جهازك');
    } catch (e) {
      if (!mounted) return;
      _snack('تعذر حفظ النسخة على جهازك');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _openBook() {
    if (_chapters.isEmpty) {
      _snack('لا توجد أقسام للقراءة في هذا الكتاب');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookReaderScreen(bookTitle: book.title, chapters: _chapters),
      ),
    );
  }

  Future<void> _openPdf() async {
    final uri = Uri.parse(book.downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('تعذر فتح ملف PDF');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isPdfBook) return _buildPdfView();
    return _buildChaptersView();
  }

  Widget _buildPdfView() {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('فتح الكتاب PDF'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اضغط لفتح ملف الكتاب كاملاً بصيغة PDF.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersView() {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: FutureBuilder<List<Chapter>>(
        future: DataService.instance.loadChapters(book),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_chapters.isEmpty && snapshot.hasData) {
            _chapters = snapshot.data!;
          }
          final chapters = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
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
                      const SizedBox(height: 16),
                      if (_downloadedPath == null)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _downloading ? null : _saveCopy,
                            icon: _downloading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.download),
                            label: Text(_downloading ? 'جارٍ الحفظ...' : 'حفظ نسخة على جهازك'),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _openBook,
                            icon: const Icon(Icons.auto_stories),
                            label: const Text('اقرأ الكتاب الآن'),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        _downloadedPath == null
                            ? 'احفظ نسخة من الكتاب على جهازك، وبعدها اقرأ الكتاب كاملًا داخل التطبيق.'
                            : 'تم الحفظ بنجاح — اضغط «اقرأ الكتاب الآن» لعرض كل أقسام الكتاب.',
                        textAlign: TextAlign.center,
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
