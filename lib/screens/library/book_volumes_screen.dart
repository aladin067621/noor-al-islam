import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../utils/theme.dart';
import 'book_chapters_screen.dart';

/// عرض أجزاء كتاب مقسّم (مثل سنن النسائي عشرون جزءًا).
class BookVolumesScreen extends StatelessWidget {
  final Book book;
  const BookVolumesScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: book.volumeChildren.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final part = book.volumeChildren[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.gold.withOpacity(0.15),
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: AppTheme.gold, fontWeight: FontWeight.bold)),
              ),
              title: Text(part.volumeLabel.isEmpty ? part.title : part.volumeLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(part.author.isEmpty ? '' : part.author,
                  style: TextStyle(color: Colors.grey.shade600)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookChaptersScreen(book: part)),
              ),
            ),
          );
        },
      ),
    );
  }
}