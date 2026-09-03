import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import 'book_chapters_screen.dart';

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
          final books = snapshot.data!;
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
                      if (b.downloadUrl.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('PDF',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
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
                    MaterialPageRoute(builder: (_) => BookChaptersScreen(book: b)),
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
