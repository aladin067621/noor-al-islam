import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import 'adhkar_list_screen.dart';

class AdhkarCategoriesScreen extends StatelessWidget {
  const AdhkarCategoriesScreen({super.key});

  static const _categories = [
    {'key': 'morning', 'title': 'أذكار الصباح', 'icon': Icons.wb_sunny},
    {'key': 'evening', 'title': 'أذكار المساء', 'icon': Icons.nightlight_round},
    {'key': 'before_sleep', 'title': 'أذكار قبل النوم', 'icon': Icons.bedtime},
    {'key': 'travel', 'title': 'أذكار السفر', 'icon': Icons.flight},
    {'key': 'misc', 'title': 'أذكار متنوعة', 'icon': Icons.auto_awesome},
    {'key': 'hisn_all', 'title': 'حصن المسلم — جميع الأبواب', 'icon': Icons.menu_book},
    {'key': 'wabil_all', 'title': 'الوابل الصيب — جميع الأبواب', 'icon': Icons.auto_stories},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأذكار')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final c = _categories[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                child: Icon(c['icon'] as IconData, color: AppTheme.primaryGreen),
              ),
              title: Text(c['title'] as String,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdhkarListScreen(
                    categoryKey: c['key'] as String,
                    title: c['title'] as String,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
