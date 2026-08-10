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
                hintText: 'ابحث عن سورة...',
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
                final surahs = snapshot.data!
                    .where((s) =>
                        _query.isEmpty || (s['name'] as String).contains(_query))
                    .toList();
                if (surahs.isEmpty) {
                  return const Center(child: Text('لا توجد نتائج'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: surahs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final s = surahs[index] as Map<String, dynamic>;
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
