import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import 'tafsir_surah_screen.dart';

class TafsirSurahsScreen extends StatefulWidget {
  const TafsirSurahsScreen({super.key});

  @override
  State<TafsirSurahsScreen> createState() => _TafsirSurahsScreenState();
}

class _TafsirSurahsScreenState extends State<TafsirSurahsScreen> {
  String _query = '';

  List<Map<String, dynamic>> _matchSurahs(List<dynamic> surahs, String q) {
    return surahs
        .where((s) => (s['name'] as String).contains(q))
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// البحث عن الآيات: يظهر اقتراحًا لكل آية يبدأ/يحتوي نصها على ما كتبه المستخدم
  List<Map<String, dynamic>> _matchAyat(List<dynamic> surahs, String q) {
    final results = <Map<String, dynamic>>[];
    for (final s in surahs) {
      final ayat = (s['ayat'] as List?) ?? [];
      for (final a in ayat) {
        final text = (a['text'] as String? ?? '');
        if (text.contains(q)) {
          results.add({
            'surahId': s['id'],
            'surahName': s['name'],
            'ayahNumber': a['number'],
            'text': text,
          });
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفسير القرآن')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة أو اكتب بداية آية...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: DataService.instance.loadTafsirSurahs(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final surahs = snapshot.data!;
                final q = _query;

                if (q.isEmpty) {
                  return _buildSurahList(surahs.where((s) => true).toList());
                }

                final matchedSurahs = _matchSurahs(surahs, q);
                final matchedAyat = _matchAyat(surahs, q);

                if (matchedSurahs.isEmpty && matchedAyat.isEmpty) {
                  return const Center(child: Text('لا توجد نتائج'));
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    if (matchedSurahs.isNotEmpty) ...[
                      const _SectionHeader(title: 'السور'),
                      ...matchedSurahs.map(
                        (s) => _surahCard(s),
                      ),
                    ],
                    if (matchedAyat.isNotEmpty) ...[
                      const _SectionHeader(title: 'الآيات المطابقة'),
                      ...matchedAyat.take(40).map(
                            (a) => _ayahSuggestionCard(a),
                          ),
                      if (matchedAyat.length > 40)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'يوجد ${matchedAyat.length - 40} نتيجة أخرى — اكتب المزيد من الآية',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(List<dynamic> surahs) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: surahs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final s = surahs[index] as Map<String, dynamic>;
        return _surahCard(s);
      },
    );
  }

  Widget _surahCard(Map<String, dynamic> s) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
          child: Text('${s['id']}',
              style: const TextStyle(
                  color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
        ),
        title: Text('سورة ${s['name']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text('${s['ayahCount']} آيات'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TafsirSurahScreen(surah: s)),
        ),
      ),
    );
  }

  Widget _ayahSuggestionCard(Map<String, dynamic> a) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.gold.withOpacity(0.15),
          child: Text('${a['surahId']}',
              style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Text(
          'سورة ${a['surahName']} — آية ${a['ayahNumber']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${a['text']}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: AppTheme.quranFontFamily,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        trailing: const Icon(Icons.chevron_left, size: 20),
        onTap: () async {
          final surahs = await DataService.instance.loadTafsirSurahs();
          final s = surahs.cast<Map<String, dynamic>>().firstWhere(
                (s) => s['id'] == a['surahId'],
              );
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TafsirSurahScreen(
                surah: s,
                initialAyah: a['ayahNumber'] as int,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.gold,
        ),
      ),
    );
  }
}