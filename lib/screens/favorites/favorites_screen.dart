import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/theme.dart';
import '../../services/favorites_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  IconData _typeIcon(String type) {
    switch (type) {
      case 'dhikr':
        return Icons.spa;
      case 'ayah':
        return Icons.menu_book;
      case 'chapter':
        return Icons.library_books;
      case 'section':
        return Icons.brightness_7;
      default:
        return Icons.favorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesService>();
    final items = favorites.items;

    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('لا توجد عناصر في المفضلة بعد',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(_typeIcon(item.type), size: 18, color: AppTheme.gold),
                            const SizedBox(width: 6),
                            Text(item.typeLabel,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: item.preview));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('تم النسخ'),
                                      duration: Duration(seconds: 1)),
                                );
                              },
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.share_outlined, size: 18),
                              onPressed: () => Share.share(item.preview),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                              onPressed: () => favorites.remove(item.key),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item.preview,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: AppTheme.quranFontFamily,
                                fontSize: 17,
                                height: 1.8)),
                        if (item.subtitle != null && item.subtitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(item.subtitle!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
