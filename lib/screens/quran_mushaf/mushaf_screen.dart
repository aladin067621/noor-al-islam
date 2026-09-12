import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/quran_models.dart';
import '../../services/quran_data_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/tajweed_text.dart' show toArabicDigits;
import 'mushaf_reader_screen.dart';
import 'tajweed_rules_screen.dart';

/// المصحف المنفصل «القرآن الكريم» — قائمة السور مع بطاقة استئناف القراءة
class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  QuranSurahMeta? _bookmarkSurah;
  int? _bookmarkAyah;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyMushafBookmark);
    int? surahId;
    int? ayah;
    if (raw != null) {
      final p = raw.split(':');
      if (p.length == 2) {
        surahId = int.tryParse(p[0]);
        ayah = int.tryParse(p[1]);
      }
    }
    QuranSurahMeta? meta;
    if (surahId != null && ayah != null) {
      final metas = await QuranDataService.instance.loadSurahsMeta();
      for (final m in metas) {
        if (m.id == surahId) {
          meta = m;
          break;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _bookmarkSurah = meta;
      _bookmarkAyah = ayah;
    });
  }

  Future<void> _openReader(int surahId, {int initialAyah = 1}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafReaderScreen(
          surahId: surahId,
          initialAyah: initialAyah,
        ),
      ),
    );
    if (mounted) await _loadBookmark();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        actions: [
          IconButton(
            tooltip: 'أحكام التجويد',
            icon: const Icon(Icons.menu_book),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TajweedRulesScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_bookmarkSurah != null && _bookmarkAyah != null)
            _resumeCard(),
          Expanded(
            child: FutureBuilder<List<QuranSurahMeta>>(
              future: QuranDataService.instance.loadSurahsMeta(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final surahs = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: surahs.length,
                  itemBuilder: (context, index) => _surahTile(surahs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumeCard() {
    final s = _bookmarkSurah!;
    final a = _bookmarkAyah!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0x22B8860B),
            child: Icon(Icons.bookmark, color: AppTheme.gold),
          ),
          title: const Text('استئناف القراءة',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('سورة ${s.nameArabic} — آية ${toArabicDigits(a)}'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => _openReader(s.id, initialAyah: a),
        ),
      ),
    );
  }

  Widget _surahTile(QuranSurahMeta s) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
          child: Text(
            toArabicDigits(s.id),
            style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ),
        title: Text('سورة ${s.nameArabic}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text('${toArabicDigits(s.numberOfAyahs)} آية'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => _openReader(s.id),
      ),
    );
  }
}