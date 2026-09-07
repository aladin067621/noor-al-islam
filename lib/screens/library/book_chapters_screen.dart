import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
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
  List<Chapter> _chapters = [];
  bool _saved = false;

  Book get book => widget.book;
  bool get _isPdfBook => book.downloadUrl.isNotEmpty;
  // الكتاب المضمّن في التطبيق (ملف فصول محلي) — يُقرأ مباشرة دون حفظ نسخة
  bool get _isEmbeddedBook => book.assetFile.isNotEmpty && book.downloadUrl.isEmpty;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final svc = BookDownloadService.instance;
    final saved = _isPdfBook
        ? await svc.isPdfSaved(book.id)
        : await svc.isBookSaved(book.id);
    if (mounted && saved != _saved) setState(() => _saved = saved);
  }

  Future<void> _saveCopy() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final path = await BookDownloadService.instance
          .downloadJson(book.id, _chapters);
      if (!mounted) return;
      setState(() => _saved = path != null);
      _snack(path != null ? 'تم حفظ نسخة الكتاب على جهازك' : 'تعذر حفظ النسخة');
    } catch (e) {
      if (!mounted) return;
      _snack('تعذر حفظ النسخة على جهازك');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _removeSaved() async {
    await BookDownloadService.instance.deleteBook(book.id);
    if (mounted) {
      setState(() => _saved = false);
      _snack('أُزيلت النسخة المحفوظة');
    }
  }

  Future<void> _openBook() async {
    if (_chapters.isEmpty) {
      try {
        _chapters = await DataService.instance.loadChapters(book);
      } catch (_) {}
    }
    if (!mounted) return;
    if (_chapters.isEmpty) {
      _snack('لا توجد أقسام للقراءة في هذا الكتاب');
      return;
    }
    // الكتب المضمّنة تُقرأ مباشرةً من الأصول — لا حاجة لحفظ نسخة أولاً
    if (!_isEmbeddedBook) {
      final path = await BookDownloadService.instance.bookFilePath(book.id);
      if (!mounted) return;
      if (path == null) {
        _snack('احفظ النسخة أولاً ثم اقرأ الكتاب');
        return;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookReaderScreen(bookTitle: book.title, chapters: _chapters),
      ),
    );
  }

  // ==================== قسم ملفات PDF ====================

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    final path = await BookDownloadService.instance.ensurePdf(book.id, book.downloadUrl);
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _saved = path != null;
    });
    if (path == null) _snack('تعذر تنزيل الملف — تحقق من الاتصال بالإنترنت');
  }

  /// فتح ملف PDF محفوظ محليًا عبر open_filex (قارئ داخل الجهاز)
  Future<void> _openLocalPdf() async {
    final path = await BookDownloadService.instance.pdfFilePath(book.id);
    if (path == null) {
      _snack('الملف غير محفوظ على هذا الجهاز');
      return;
    }
    final result = await OpenFilex.open(path, type: 'application/pdf');
    if (result == null || result.type == null || result.type != 'done') {
      _snack('تعذر فتح ملف PDF — لا يوجد قارئ PDF مثبت على الجهاز');
    }
  }

  Future<void> _removePdf() async {
    await BookDownloadService.instance.deletePdf(book.id);
    if (mounted) {
      setState(() => _saved = false);
      _snack('أُزيل الملف المحفوظ');
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
                  if (!_saved)
                    FilledButton.icon(
                      onPressed: _downloading ? null : _downloadPdf,
                      icon: _downloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(_downloading ? 'جارٍ التحميل...' : 'تحميل نسخة PDF على جهازك'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _openLocalPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('فتح الكتاب PDF'),
                    ),
                  const SizedBox(height: 6),
                  if (_saved)
                    TextButton(
                      onPressed: _removePdf,
                      child: const Text('إزالة النسخة المحفوظة',
                          style: TextStyle(color: AppTheme.dangerRed)),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _saved
                        ? 'النسخة محفوظة على جهازك ويمكن فتحها دون إنترنت.'
                        : 'حمّل النسخة مرة واحدة ثم تُفتح من جهازك مباشرةً دون إنترنت.',
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
                      if (_isEmbeddedBook) ...[
                        FilledButton.icon(
                          onPressed: _openBook,
                          icon: const Icon(Icons.auto_stories),
                          label: const Text('اقرأ الكتاب الآن'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'الكتاب مضمّن في التطبيق — تُقرأ أقسامه مباشرةً دون اتصال بالإنترنت.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600, height: 1.6),
                        ),
                      ] else if (!_saved)
                        FilledButton.icon(
                          onPressed: _downloading ? null : _saveCopy,
                          icon: _downloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download),
                          label: Text(_downloading ? 'جارٍ الحفظ...' : 'حفظ نسخة على جهازك'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _openBook,
                          icon: const Icon(Icons.auto_stories),
                          label: const Text('اقرأ الكتاب الآن'),
                        ),
                      const SizedBox(height: 6),
                      if (!_isEmbeddedBook && _saved)
                        TextButton(
                          onPressed: _removeSaved,
                          child: const Text('إزالة النسخة المحفوظة',
                              style: TextStyle(color: AppTheme.dangerRed)),
                        ),
                      const SizedBox(height: 6),
                      if (!_isEmbeddedBook)
                      Text(
                        _saved
                            ? 'تم الحفظ بنجاح — اضغط «اقرأ الكتاب الآن» لعرض كل أقسام الكتاب.'
                            : 'احفظ نسخة من الكتاب على جهازك، وبعدها اقرأ الكتاب كاملًا داخل التطبيق.',
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