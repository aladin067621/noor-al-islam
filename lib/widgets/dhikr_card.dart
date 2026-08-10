import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/dhikr.dart';
import '../utils/theme.dart';
import '../services/favorites_service.dart';

/// بطاقة ذكر تفاعلية: عداد تكرار، نسخ، مشاركة، مفضلة
class DhikrCard extends StatefulWidget {
  final Dhikr dhikr;
  const DhikrCard({super.key, required this.dhikr});

  @override
  State<DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends State<DhikrCard> {
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.dhikr.repetitions;
  }

  void _tapCounter() {
    if (_remaining > 0) {
      setState(() => _remaining--);
    } else {
      setState(() => _remaining = widget.dhikr.repetitions);
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.dhikr.shareText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الذكر'), duration: Duration(seconds: 1)),
    );
  }

  void _share() {
    Share.share(widget.dhikr.shareText());
  }

  FavoriteItem _favItem() => FavoriteItem(
        key: widget.dhikr.favoriteKey,
        type: 'dhikr',
        typeLabel: 'ذكر',
        preview: widget.dhikr.text,
        subtitle: widget.dhikr.source,
      );

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesService>();
    final isFav = favorites.isFavorite(widget.dhikr.favoriteKey);
    final done = _remaining == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // نص الذكر
            SelectableText(
              widget.dhikr.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.quranFontFamily,
                fontSize: 20,
                height: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.dhikr.virtue != null && widget.dhikr.virtue!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'الفضل: ${widget.dhikr.virtue}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.gold, fontWeight: FontWeight.bold),
                ),
              ),
            // المصدر
            if (widget.dhikr.source.isNotEmpty)
              Text(
                widget.dhikr.source,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // عداد التكرار
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _tapCounter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: done
                          ? Colors.green.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(done ? Icons.check_circle : Icons.touch_app,
                            size: 20,
                            color: done ? Colors.green : Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          done ? 'تم' : '$_remaining',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: done ? Colors.green : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'نسخ',
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: _copy,
                    ),
                    IconButton(
                      tooltip: 'مشاركة',
                      icon: const Icon(Icons.share_outlined),
                      onPressed: _share,
                    ),
                    IconButton(
                      tooltip: 'المفضلة',
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : null),
                      onPressed: () => favorites.toggle(_favItem()),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
