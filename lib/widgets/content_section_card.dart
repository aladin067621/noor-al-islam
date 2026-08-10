import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/theme.dart';
import '../services/favorites_service.dart';

/// بطاقة محتوى عامة (للتوحيد وأركان الإسلام): عنوان + نص + مصدر + مفضلة/مشاركة
class ContentSectionCard extends StatelessWidget {
  final String id;
  final String title;
  final String content;
  final String source;
  final String typeLabel; // مثل "التوحيد"

  const ContentSectionCard({
    super.key,
    required this.id,
    required this.title,
    required this.content,
    required this.source,
    required this.typeLabel,
  });

  String get _favKey => 'section:$id';

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesService>();
    final isFav = favorites.isFavorite(_favKey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.brightness_7, color: AppTheme.gold, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(content, style: const TextStyle(fontSize: 16, height: 1.9)),
            if (source.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('المصدر: $source',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'نسخ',
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '$title\n\n$content\n\nالمصدر: $source'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم النسخ'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'مشاركة',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => Share.share('$title\n\n$content\n\nالمصدر: $source'),
                ),
                IconButton(
                  tooltip: 'المفضلة',
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : null),
                  onPressed: () => favorites.toggle(FavoriteItem(
                    key: _favKey,
                    type: 'section',
                    typeLabel: typeLabel,
                    preview: '$title — $content',
                    subtitle: source,
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
