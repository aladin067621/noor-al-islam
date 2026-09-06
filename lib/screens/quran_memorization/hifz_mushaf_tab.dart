import 'package:flutter/material.dart';
import '../../models/quran_models.dart';
import '../../services/hifz_service.dart';
import '../../services/quran_data_service.dart';
import '../../utils/theme.dart';
import '../../widgets/tajweed_text.dart';
import 'hifz_reader_screen.dart';

/// تبويب المصحف — قائمة السور واختيار الجزء
class HifzMushafTab extends StatefulWidget {
  const HifzMushafTab({super.key});

  @override
  State<HifzMushafTab> createState() => _HifzMushafTabState();
}

class _HifzMushafTabState extends State<HifzMushafTab> {
  List<QuranSurahMeta>? _metas;
  List<JuzInfo>? _juz;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = QuranDataService.instance;
    final metas = await data.loadSurahsMeta();
    final juz = await data.loadJuz();
    if (!mounted) return;
    setState(() {
      _metas = metas;
      _juz = juz;
    });
  }

  void _openJuz() {
    final juz = _juz;
    if (juz == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: juz.length,
          itemBuilder: (context, i) {
            final j = juz[i];
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.gold.withOpacity(0.15),
                child: Text(
                  toArabicDigits(j.id),
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text('الجزء ${toArabicDigits(j.id)} — ${j.nameArabic}'),
              subtitle: Text(
                  'يبدأ من سورة ${toArabicDigits(j.startSurah)} آية ${toArabicDigits(j.startAyah)}'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HifzReaderScreen(
                      surahId: j.startSurah,
                      initialAyah: j.startAyah,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _juz == null ? null : _openJuz,
                icon: const Icon(Icons.workspaces_outline),
                label: const Text('اختيار الجزء'),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: HifzService.instance,
                builder: (context, _) {
                  final hifz = HifzService.instance;
                  return Row(
                    children: [
                      const Text('ألوان التجويد', style: TextStyle(fontSize: 13)),
                      Switch(
                        value: hifz.settings.tajweed,
                        onChanged: (v) {
                          hifz.settings.tajweed = v;
                          hifz.saveSettings();
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _metas == null
              ? const Center(child: CircularProgressIndicator())
              : AnimatedBuilder(
                  animation: HifzService.instance,
                  builder: (context, _) => ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: _metas!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final s = _metas![index];
                      return _surahTile(s);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _surahTile(QuranSurahMeta s) {
    final hifz = HifzService.instance;
    final mem = hifz.memCountOfSurah(s.id);
    final frac = s.numberOfAyahs == 0 ? 0.0 : mem / s.numberOfAyahs;
    final color = hifzStatusColor(frac >= 1.0 ? 1 : null);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HifzReaderScreen(
              surahId: s.id,
              initialAyah: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
                child: Text(
                  toArabicDigits(s.id),
                  style: const TextStyle(
                      color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سورة ${s.nameArabic}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${toArabicDigits(s.numberOfAyahs)} آية · الصفحة ${toArabicDigits(s.pageStart)}–${toArabicDigits(s.pageEnd)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (mem > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            'محفوظ ${toArabicDigits(mem)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade300,
                        color: hifzStatusColor(frac >= 1.0 ? 1 : (frac > 0 ? 2 : null)),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}