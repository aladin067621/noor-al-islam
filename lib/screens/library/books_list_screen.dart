import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import 'book_chapters_screen.dart';
import 'book_volumes_screen.dart';

/// النسخ المضمّنة (ملف فصول في التطبيق) للكتب التي لها إصدار «الكتاب الكامل» بصيغة PDF —
/// تُخفى من قائمة المكتبة حتى لا تتكرر، مع بقاء إصدار الـ PDF الكامل ظاهرًا.
/// ملاحظة: لا تُحذف من index.json لأن بطاقة «الأربعون النووية» في الصفحة الرئيسية
/// تفتح النسخة المضمّنة منها مباشرةً عبر loadBooksIndex().
const Set<String> _hiddenEmbeddedDuplicates = {
  'three_foundations', // ↔ usul_thalatha (PDF)
  'four_rules', // ↔ qawaaid_arba (PDF)
  'nawaqid', // ↔ nawaqid_pdf (PDF)
  'tawheed_book', // ↔ kitab_tawheed (PDF)
  'kashf_shubhat', // ↔ kashf_shubhat_pdf (PDF)
  'arbaeen', // ↔ arbaeen_nawawi (PDF)
};

class BooksListScreen extends StatelessWidget {
  const BooksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المكتبة')),
      body: FutureBuilder<List<Book>>(
        future: DataService.instance.loadBooksIndex(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data!
              .where((b) => !_hiddenEmbeddedDuplicates.contains(b.id))
              .toList();
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final b = books[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.gold.withOpacity(0.15),
                    child: const Icon(Icons.menu_book, color: AppTheme.gold),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(b.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      ),
                      if (b.assetFile.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('في التطبيق',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                        ),
                      if (b.downloadUrl.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('PDF',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${b.author}\n${b.benefit}',
                        style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => b.volumeChildren.isNotEmpty
                          ? BookVolumesScreen(book: b)
                          : BookChaptersScreen(book: b),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
