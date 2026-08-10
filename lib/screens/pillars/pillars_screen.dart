import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import '../../widgets/content_section_card.dart';

class PillarsScreen extends StatelessWidget {
  const PillarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أركان الإسلام')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: DataService.instance.loadPillars(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final intro = data['intro'] as String? ?? '';
          final sections = (data['sections'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (intro.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(intro,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: AppTheme.quranFontFamily, fontSize: 16, height: 1.9)),
                ),
              ...sections.map((e) {
                final s = e as Map<String, dynamic>;
                return ContentSectionCard(
                  id: s['id'] ?? '',
                  title: s['title'] ?? '',
                  content: s['content'] ?? '',
                  source: s['source'] ?? '',
                  typeLabel: 'أركان الإسلام',
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
