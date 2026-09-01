import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/chapter.dart';
import '../../utils/theme.dart';
import '../../services/favorites_service.dart';

/// قارئ الكتاب كاملًا: يعرض كل أقسام الكتاب على التوالي داخل صفحة واحدة.
class BookReaderScreen extends StatelessWidget {
  final String bookTitle;
  final List<Chapter> chapters;
  const BookReaderScreen({super.key, required this.bookTitle, required this.chapters});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(bookTitle, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'نسخ الكتاب كاملًا',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              final all = chapters.map((c) => '${c.title}\n\n${c.content}').join('\n\n\n');
              Clipboard.setData(ClipboardData(text: all));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ الكتاب كاملًا'), duration: Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            tooltip: 'مشاركة الكتاب كاملًا',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final all = chapters.map((c) => '${c.title}\n\n${c.content}').join('\n\n\n');
              Share.share(all);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(bookTitle,
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (chapters.isEmpty)
              const Text('لا توجد أقسام لعرضها')
            else
              for (var i = 0; i < chapters.length; i++) ...[
                if (i > 0) const Divider(height: 40),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(chapters[i].title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'المفضلة',
                      icon: Icon(
                          favorites.isFavorite(chapters[i].favoriteKey)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: favorites.isFavorite(chapters[i].favoriteKey)
                              ? Colors.redAccent
                              : null),
                      onPressed: () => favorites.toggle(FavoriteItem(
                        key: chapters[i].favoriteKey,
                        type: 'chapter',
                        typeLabel: 'فصل كتاب',
                        preview: '${chapters[i].title} — ${chapters[i].content}',
                        subtitle: chapters[i].bookTitle,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  chapters[i].content,
                  style: const TextStyle(
                    fontFamily: AppTheme.quranFontFamily,
                    fontSize: 19,
                    height: 2.1,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
