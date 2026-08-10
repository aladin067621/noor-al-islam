import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../widgets/content_section_card.dart';

class TawheedScreen extends StatelessWidget {
  const TawheedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التوحيد')),
      body: FutureBuilder<List<dynamic>>(
        future: DataService.instance.loadTawheedSections(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sections = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final s = sections[index] as Map<String, dynamic>;
              return ContentSectionCard(
                id: s['id'] ?? 'tw_$index',
                title: s['title'] ?? '',
                content: s['content'] ?? '',
                source: s['source'] ?? '',
                typeLabel: 'التوحيد',
              );
            },
          );
        },
      ),
    );
  }
}
