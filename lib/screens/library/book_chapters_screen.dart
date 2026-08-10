import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import 'chapter_reader_screen.dart';

class BookChaptersScreen extends StatelessWidget {
  final Book book;
  const BookChaptersScreen({super.key, required this.book});

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
                      const SizedBox(height: 10),
                      Text('المرجع: ${book.reference}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text('الفصول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ...chapters.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
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
