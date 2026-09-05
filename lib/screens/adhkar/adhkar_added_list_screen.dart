import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/adhkar_category.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'adhkar_list_screen.dart';
import 'adhkar_picker_screen.dart';

/// شاشة "قائمة إضافية": تعرض فقط الفئات التي أضافها المستخدم بنفسه.
class AdhkarAddedListScreen extends StatefulWidget {
  const AdhkarAddedListScreen({super.key});

  @override
  State<AdhkarAddedListScreen> createState() => _AdhkarAddedListScreenState();
}

class _AdhkarAddedListScreenState extends State<AdhkarAddedListScreen> {
  List<AdhkarCategory> _categories = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Set<String>> _loadAddedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(AppConstants.keyAddedAdhkarCategories) ?? [])
        .toSet();
  }

  Future<void> _load() async {
    final byKey = await DataService.instance.loadHisnWabilCategoriesByKey();
    final keys = await _loadAddedKeys();
    if (mounted) {
      setState(() {
        _categories = keys.map((k) => byKey[k]).whereType<AdhkarCategory>().toList();
        _loaded = true;
      });
    }
  }

  Future<void> _remove(String uniqueKey) async {
    final keys = await _loadAddedKeys();
    keys.remove(uniqueKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.keyAddedAdhkarCategories, keys.toList());
    if (mounted) setState(() => _categories.removeWhere((c) => c.uniqueKey == uniqueKey));
  }

  Future<void> _openPicker() async {
    final byKey = await DataService.instance.loadHisnWabilCategoriesByKey();
    final existing = await _loadAddedKeys();
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => AdhkarPickerScreen(exclude: existing, allKeys: byKey.keys.toList()),
      ),
    );
    if (selected != null && selected.isNotEmpty) {
      final keys = await _loadAddedKeys();
      keys.addAll(selected);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(AppConstants.keyAddedAdhkarCategories, keys.toList());
      if (mounted) {
        setState(() {
          _categories = keys.map((k) => byKey[k]).whereType<AdhkarCategory>().toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تمّت إضافة ${selected.length} إلى القائمة الإضافية')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قائمة إضافية')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.playlist_add, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('لا توجد أقسام في القائمة الإضافية بعد'),
                      const SizedBox(height: 6),
                      Text(
                        'اضغط "أضف قسماً" لاختيار أذكار من حصن المسلم أو الوابل الصيب',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isHisn = category.book == 'حصن المسلم';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (isHisn ? AppTheme.primaryGreen : AppTheme.gold).withOpacity(0.15),
                          child: Icon(
                            isHisn ? Icons.menu_book : Icons.auto_stories,
                            color: isHisn ? AppTheme.primaryGreen : AppTheme.gold,
                          ),
                        ),
                        title: Text(category.title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${category.book} — ${category.items.length} أذكار',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'إزالة من القائمة الإضافية',
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _remove(category.uniqueKey),
                            ),
                            const Icon(Icons.chevron_left),
                          ],
                        ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPicker,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('أضف قسماً'),
      ),
    );
  }
}
