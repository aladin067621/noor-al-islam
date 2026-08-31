import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/adhkar_category.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'adhkar_list_screen.dart';
import 'adhkar_picker_screen.dart';

/// شاشة "أذكار أخرى": تعرض فئات حصن المسلم والوابل الصيب معاً،
/// قابلة لإعادة الترتيب بالسحب ويمكن تثبيتها.
class AdhkarSubCategoriesScreen extends StatefulWidget {
  const AdhkarSubCategoriesScreen({super.key});

  @override
  State<AdhkarSubCategoriesScreen> createState() =>
      _AdhkarSubCategoriesScreenState();
}

class _AdhkarSubCategoriesScreenState extends State<AdhkarSubCategoriesScreen> {
  List<AdhkarCategory> _categories = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hisn = await DataService.instance.loadHisnCategories();
    final wabil = await DataService.instance.loadWabilCategories();
    // أضف المواد المتنوعة المتبقية (من other_adhkar.json) كقسم أول
    final otherDhikr = await DataService.instance.loadAdhkar('other');
    final otherCat = AdhkarCategory(
      key: 'other_misc',
      title: 'أذكار أخرى (متنوعة)',
      items: otherDhikr,
      book: 'أذكار متنوعة',
    );
    final all = [otherCat, ...hisn, ...wabil];

    // طبق الترتيب المحفوظ إن وُجد
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList(AppConstants.keySubAdhkarOrder) ?? [];
    if (stored.isNotEmpty) {
      final byKey = {for (final c in all) c.uniqueKey: c};
      final ordered = <AdhkarCategory>[];
      for (final k in stored) {
        final c = byKey[k];
        if (c != null && !ordered.any((x) => x.uniqueKey == k)) ordered.add(c);
      }
      for (final c in all) {
        if (!ordered.any((x) => x.uniqueKey == c.uniqueKey)) ordered.add(c);
      }
      if (mounted) setState(() => _categories = ordered);
    } else {
      if (mounted) setState(() => _categories = all);
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.keySubAdhkarOrder,
        _categories.map((c) => c.uniqueKey).toList());
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final c = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, c);
    });
    _saveOrder();
  }

  Future<void> _openPicker() async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => const AdhkarPickerScreen()),
    );
    if (selected != null && selected.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تمّت إضافة ${selected.length} فئة إلى أذكار أخرى')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أذكار أخرى')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'فئات من حصن المسلم والوابل الصيب — اسحب لإعادة الترتيب',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isHisn = category.book == 'حصن المسلم';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (isHisn ? AppTheme.primaryGreen : AppTheme.gold)
                                    .withOpacity(0.15),
                            child: Icon(
                              isHisn ? Icons.menu_book : Icons.auto_stories,
                              color:
                                  isHisn ? AppTheme.primaryGreen : AppTheme.gold,
                            ),
                          ),
                          title: Text(category.title,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${category.book} — ${category.items.length} أذكار',
                            style:
                                const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdhkarListScreen(
                                  categoryKey: category.key,
                                  title: category.title,
                                  category: category),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPicker,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('أضف فئة'),
      ),
    );
  }
}
