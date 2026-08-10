import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/chapter.dart';
import '../../utils/theme.dart';
import '../../services/favorites_service.dart';

class ChapterReaderScreen extends StatelessWidget {
  final Chapter chapter;
  const ChapterReaderScreen({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesService>();
    final isFav = favorites.isFavorite(chapter.favoriteKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(chapter.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'نسخ',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: chapter.shareText()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم النسخ'), duration: Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            tooltip: 'مشاركة',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(chapter.shareText()),
          ),
          IconButton(
            tooltip: 'المفضلة',
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.redAccent : null),
            onPressed: () => favorites.toggle(FavoriteItem(
              key: chapter.favoriteKey,
              type: 'chapter',
              typeLabel: 'فصل كتاب',
              preview: '${chapter.title} — ${chapter.content}',
              subtitle: chapter.bookTitle,
            )),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(chapter.bookTitle,
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(chapter.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            SelectableText(
              chapter.content,
              style: const TextStyle(
                fontFamily: AppTheme.quranFontFamily,
                fontSize: 19,
                height: 2.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
