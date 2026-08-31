import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'adhkar_list_screen.dart';
import 'adhkar_sub_categories_screen.dart';
import 'adhkar_picker_screen.dart';

/// فئة أذكار قابلة للسحب والإفلات وإعادة الترتيب
class AdhkarCategoriesScreen extends StatefulWidget {
  const AdhkarCategoriesScreen({super.key});

  @override
  State<AdhkarCategoriesScreen> createState() => _AdhkarCategoriesScreenState();
}

class _AdhkarCategoriesScreenState extends State<AdhkarCategoriesScreen> {
  List<_AdhkarEntry> _entries = _defaultEntries();
  bool _loaded = false;
  Set<String> _pinned = {};

  static List<_AdhkarEntry> _defaultEntries() => [
        _AdhkarEntry(
            key: 'morning', title: 'أذكار الصباح', icon: Icons.wb_sunny),
        _AdhkarEntry(
            key: 'evening', title: 'أذكار المساء', icon: Icons.nightlight_round),
        _AdhkarEntry(
            key: 'before_sleep', title: 'أذكار قبل النوم', icon: Icons.bedtime),
        _AdhkarEntry(key: 'travel', title: 'أذكار السفر', icon: Icons.flight),
        _AdhkarEntry(key: 'prayer', title: 'أذكار الصلاة', icon: Icons.mosque),
        _AdhkarEntry(
            key: 'sub_other', title: 'أذكار أخرى', icon: Icons.list),
        _AdhkarEntry(
            key: 'hisn_all',
            title: 'حصن المسلم — جميع الأبواب',
            icon: Icons.menu_book),
        _AdhkarEntry(
            key: 'wabil_all',
            title: 'الوابل الصيب — جميع الأبواب',
            icon: Icons.auto_stories),
      ];

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.keyAdhkarOrder) ?? [];
    if (stored.isNotEmpty) {
      final byKey = {for (final e in _entries) e.key: e};
      final ordered = <_AdhkarEntry>[];
      for (final k in stored) {
        final e = byKey[k];
        if (e != null && !ordered.any((x) => x.key == k)) ordered.add(e);
      }
      for (final e in _entries) {
        if (!ordered.any((x) => x.key == e.key)) ordered.add(e);
      }
      if (mounted) setState(() => _entries = ordered);
    }
    // تحميل الأقسام المثبّتة
    final pinned = prefs.getStringList(AppConstants.keyPinnedAdhkar) ?? [];
    if (mounted) setState(() => _pinned = pinned.toSet());
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        AppConstants.keyAdhkarOrder, _entries.map((e) => e.key).toList());
  }

  Future<void> _togglePin(String key) async {
    setState(() {
      if (_pinned.contains(key)) {
        _pinned.remove(key);
      } else {
        _pinned.add(key);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        AppConstants.keyPinnedAdhkar, _pinned.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_pinned.contains(key)
              ? 'تم تثبيت القسم في الصفحة الرئيسية'
              : 'تمت إزالة التثبيت'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final entry = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, entry);
    });
    _saveOrder();
  }

  void _open(_AdhkarEntry entry) {
    final key = entry.key;
    if (key == 'sub_other') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AdhkarSubCategoriesScreen()));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdhkarListScreen(categoryKey: key, title: entry.title),
      ),
    );
  }

  Future<void> _openPicker() async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => const AdhkarPickerScreen()),
    );
    if (selected != null && selected.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('تمّت إضافة ${selected.length} قسم إلى أذكار أخرى')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأذكار')),
      body: _loaded
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'اسحب القسم لإعادة ترتيبه كما تريد',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                    itemCount: _entries.length,
                    onReorder: _onReorder,
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      final pinnable = const [
                        'morning',
                        'evening',
                        'before_sleep',
                        'travel',
                        'prayer'
                      ].contains(entry.key);
                      return _EntryTile(
                        key: ValueKey(entry.key),
                        entry: entry,
                        index: index,
                        pinned: pinnable && _pinned.contains(entry.key),
                        onPin: pinnable ? () => _togglePin(entry.key) : null,
                        onTap: () => _open(entry),
                      );
                    },
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPicker,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('أضف قسماً جديداً'),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final _AdhkarEntry entry;
  final int index;
  final bool pinned;
  final VoidCallback? onPin;
  final VoidCallback onTap;
  const _EntryTile(
      {super.key,
      required this.entry,
      required this.index,
      required this.pinned,
      required this.onPin,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
          child: Icon(entry.icon, color: AppTheme.primaryGreen),
        ),
        title: Text(entry.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPin != null)
              IconButton(
                tooltip: pinned ? 'إزالة التثبيت' : 'تثبيت في الصفحة الرئيسية',
                icon: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 20,
                  color: pinned ? AppTheme.primaryGreen : null,
                ),
                onPressed: onPin,
              ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ),
            const Icon(Icons.chevron_left),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AdhkarEntry {
  final String key;
  final String title;
  final IconData icon;
  const _AdhkarEntry(
      {required this.key, required this.title, required this.icon});
}
