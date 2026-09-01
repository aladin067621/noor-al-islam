import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/theme.dart';
import '../../services/favorites_service.dart';

class TafsirSurahScreen extends StatefulWidget {
  final Map<String, dynamic> surah;

  /// عند البحث عن آية: يُحدد رقم الآية للانتقال إليها وتمييزها
  final int? initialAyah;

  const TafsirSurahScreen({super.key, required this.surah, this.initialAyah});

  @override
  State<TafsirSurahScreen> createState() => _TafsirSurahScreenState();
}

class _TafsirSurahScreenState extends State<TafsirSurahScreen> {
  bool _showTafsir = true;
  int? _highlightedAyah;
  final Map<int, GlobalKey> _ayahKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _highlightedAyah = widget.initialAyah;
    if (widget.initialAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAyah());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToAyah() {
    final target = widget.initialAyah;
    if (target == null) return;
    final ayat = (widget.surah['ayat'] as List?) ?? [];
    final index = ayat.indexWhere((a) => a['number'] == target);
    if (index < 0) return;

    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(
        (index * 200.0).clamp(0.0, _scrollController.position.maxScrollExtent),
      );
      final ctx = _ayahKeys[target]?.currentContext;
      if (ctx != null) {
        Future<void>.delayed(const Duration(milliseconds: 80), () {
          if (!mounted) return;
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            alignment: 0.3,
          );
        });
      }
    });
  }

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
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: ayat.length,
        itemBuilder: (context, index) {
          final a = ayat[index] as Map<String, dynamic>;
          final number = a['number'];
          final isTarget = _highlightedAyah == number;
          final key = _ayahKeys.putIfAbsent(number, GlobalKey.new);
          final text = a['text'] ?? '';
          final tafsir = a['tafsir'] ?? '';
          final favKey = 'ayah:${widget.surah['id']}:$number';
          final isFav = favorites.isFavorite(favKey);

          return Container(
            key: key,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: isTarget
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.gold, width: 2),
                  )
                : null,
            child: Card(
              margin: EdgeInsets.zero,
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isTarget ? AppTheme.gold.withOpacity(0.10) : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SelectableText(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: AppTheme.quranFontFamily, fontSize: 22, height: 2.0),
                      ),
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
            ),
          );
        },
      ),
    );
  }
}