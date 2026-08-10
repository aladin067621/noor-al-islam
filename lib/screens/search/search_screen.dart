import 'package:flutter/material.dart';
import '../../models/prayer_step.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';

/// نتيجة بحث موحّدة
class SearchResult {
  final String section; // القسم الذي ينتمي إليه
  final String title;
  final String preview;
  final String source;

  SearchResult({
    required this.section,
    required this.title,
    required this.preview,
    this.source = '',
  });
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<SearchResult> _all = [];
  List<SearchResult> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _buildIndex();
  }

  /// تطبيع النص العربي لبحث تقريبي (إزالة التشكيل وتوحيد الألف والهاء)
  String _normalize(String s) {
    final diacritics = RegExp('[\u064B-\u0652\u0670]');
    return s
        .replaceAll(diacritics, '')
        .replaceAll(RegExp('[إأآا]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ـ', '')
        .trim();
  }

  Future<void> _buildIndex() async {
    final data = DataService.instance;
    final results = <SearchResult>[];

    // الأذكار
    final adhkar = await data.loadAllAdhkar();
    for (final d in adhkar) {
      results.add(SearchResult(
        section: 'الأذكار',
        title: d.category.replaceAll('_', ' '),
        preview: d.text,
        source: d.source,
      ));
    }

    // الصلاة
    final tabs = await data.loadPrayerTabs();
    for (final t in tabs) {
      for (final PrayerStep s in t.steps) {
        results.add(SearchResult(
          section: 'الصلاة',
          title: s.title,
          preview: '${s.description} ${s.dhikr} ${s.evidence}'.trim(),
          source: s.source,
        ));
      }
    }

    // التوحيد
    final tw = await data.loadTawheedSections();
    for (final s in tw) {
      final m = s as Map<String, dynamic>;
      results.add(SearchResult(
        section: 'التوحيد',
        title: m['title'] ?? '',
        preview: m['content'] ?? '',
        source: m['source'] ?? '',
      ));
    }

    // أركان الإسلام
    final pillars = await data.loadPillars();
    for (final s in (pillars['sections'] as List? ?? [])) {
      final m = s as Map<String, dynamic>;
      results.add(SearchResult(
        section: 'أركان الإسلام',
        title: m['title'] ?? '',
        preview: m['content'] ?? '',
        source: m['source'] ?? '',
      ));
    }

    // الكتب
    final books = await data.loadBooksIndex();
    for (final b in books) {
      final chapters = await data.loadChapters(b);
      for (final c in chapters) {
        results.add(SearchResult(
          section: 'المكتبة — ${b.title}',
          title: c.title,
          preview: c.content,
          source: b.author,
        ));
      }
    }

    // التفسير
    final surahs = await data.loadTafsirSurahs();
    for (final s in surahs) {
      final m = s as Map<String, dynamic>;
      for (final a in (m['ayat'] as List? ?? [])) {
        final ay = a as Map<String, dynamic>;
        results.add(SearchResult(
          section: 'تفسير القرآن',
          title: 'سورة ${m['name']} — آية ${ay['number']}',
          preview: '${ay['text']} ${ay['tafsir']}',
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _all = results;
      _loading = false;
    });
  }

  void _search(String query) {
    final q = _normalize(query);
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final terms = q.split(RegExp(r'\s+'));
    setState(() {
      _results = _all.where((r) {
        final hay = _normalize('${r.title} ${r.preview} ${r.source}');
        return terms.every((t) => hay.contains(t));
      }).take(80).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ابحث في الأذكار، الكتب، الصلاة، التوحيد...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _search('');
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _search,
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _controller.text.isEmpty
                          ? 'اكتب كلمة للبحث في كل محتوى التطبيق'
                          : 'لا توجد نتائج',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final r = _results[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(r.section,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 6),
                              Text(r.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(r.preview,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(height: 1.7)),
                              if (r.source.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(r.source,
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey.shade500)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
