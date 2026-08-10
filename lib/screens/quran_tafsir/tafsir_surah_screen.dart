import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/theme.dart';
import '../../services/favorites_service.dart';

class TafsirSurahScreen extends StatefulWidget {
  final Map<String, dynamic> surah;
  const TafsirSurahScreen({super.key, required this.surah});

  @override
  State<TafsirSurahScreen> createState() => _TafsirSurahScreenState();
}

class _TafsirSurahScreenState extends State<TafsirSurahScreen> {
  bool _showTafsir = true;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesService>();
    final ayat = (widget.surah['ayat'] as List?) ?? [];
    final surahName = widget.surah['name'];

    return Scaffold(
      appBar: AppBar(
        title: Text('سورة $surahName'),
        actions: [
          Row(
            children: [
              const Text('التفسير', style: TextStyle(fontSize: 13)),
              Switch(
                value: _showTafsir,
                onChanged: (v) => setState(() => _showTafsir = v),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ayat.length,
        itemBuilder: (context, index) {
          final a = ayat[index] as Map<String, dynamic>;
          final number = a['number'];
          final text = a['text'] ?? '';
          final tafsir = a['tafsir'] ?? '';
          final favKey = 'ayah:${widget.surah['id']}:$number';
          final isFav = favorites.isFavorite(favKey);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                        child: Text('$number',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'مشاركة',
                        icon: const Icon(Icons.share_outlined, size: 20),
                        onPressed: () => Share.share('$text\n\n$tafsir'),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'المفضلة',
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                            size: 20, color: isFav ? Colors.red : null),
                        onPressed: () => favorites.toggle(FavoriteItem(
                          key: favKey,
                          type: 'ayah',
                          typeLabel: 'آية',
                          preview: '$text',
                          subtitle: 'سورة $surahName — آية $number',
                        )),
                      ),
                    ],
                  ),
                  SelectableText(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: AppTheme.quranFontFamily, fontSize: 22, height: 2.0),
                  ),
                  if (_showTafsir && tafsir.isNotEmpty) ...[
                    const Divider(height: 22),
                    Text('التفسير:',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.gold, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SelectableText(tafsir, style: const TextStyle(fontSize: 15, height: 1.9)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
