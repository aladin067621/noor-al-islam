import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/adhkar_category.dart';
import '../../models/dhikr.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../services/data_service.dart';
import '../../widgets/dhikr_card.dart';
import 'adhkar_list_screen.dart';
import 'adhkar_sub_categories_screen.dart';
import 'adhkar_personal_list_screen.dart';

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

  // البحث النصي
  String _query = '';
  List<AdhkarCategory> _searchCats = [];
  List<Dhikr> _searchDhikr = [];
  bool _searchReady = false;

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
      ];

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.keyAdhkarOrder) ?? [];

    // أقسام إضافية: فئات «أذكار أخرى» المضافة إلى القائمة الرئيسية
    final extraKeys =
        prefs.getStringList(AppConstants.keyAdhkarMainExtra) ?? [];
    final extraEntries = <_AdhkarEntry>[];
    if (extraKeys.isNotEmpty) {
      final catMap = await DataService.instance.loadHisnWabilCategoriesByKey();
      final base = {..._defaultEntries().map((e) => e.key)};
      for (final uk in extraKeys) {
        final c = catMap[uk];
        if (c != null && !base.contains(uk)) {
          extraEntries.add(_AdhkarEntry(
            key: uk,
            title: c.title,
            icon: Icons.auto_stories,
            category: c,
          ));
        }
      }
    }

    final allEntries = [
      ..._defaultEntries(),
      ...extraEntries,
    ];

    var ordered = allEntries;
    if (stored.isNotEmpty) {
      final byKey = {for (final e in allEntries) e.key: e};
      final list = <_AdhkarEntry>[];
      for (final k in stored) {
        final e = byKey[k];
        if (e != null && !list.any((x) => x.key == k)) list.add(e);
      }
      for (final e in allEntries) {
        if (!list.any((x) => x.key == e.key)) list.add(e);
      }
      ordered = list;
    }

    // تحميل الأقسام المثبّتة
    final pinned = prefs.getStringList(AppConstants.keyPinnedAdhkar) ?? [];
    if (mounted) {
      setState(() {
        _entries = ordered;
        _pinned = pinned.toSet();
        _loaded = true;
      });
    }
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
      Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdhkarSubCategoriesScreen()))
          .then((_) => _loadOrder());
      return;
    }
    if (entry.category != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdhkarListScreen(
            categoryKey: entry.category!.key,
            title: entry.title,
            category: entry.category,
          ),
        ),
      );
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

  Future<void> _openPersonalList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdhkarPersonalListScreen()),
    );
    // أعِد تحميل الأقسام المثبّتة إن تغيّرت من داخل "أذكاري"
    await _loadOrder();
  }

  /// فتح شاشة «أذكار أخرى» مباشرة لإضافة فئات إلى القائمة الرئيسية
  Future<void> _openAddFromOther() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdhkarSubCategoriesScreen()),
    );
    await _loadOrder();
  }

  /// تحميل كل الفئات والأذكار لمرة واحدة عند بدء البحث
  Future<void> _ensureSearchIndex() async {
    if (_searchReady) return;
    final catMap = await DataService.instance.loadHisnWabilCategoriesByKey();
    final allAdhkar = await DataService.instance.loadAllAdhkar();
    if (mounted) {
      setState(() {
        _searchCats = catMap.values.toList();
        _searchDhikr = allAdhkar;
        _searchReady = true;
      });
    }
  }

  void _onSearchChanged(String q) {
    setState(() => _query = q.trim());
    if (q.trim().isNotEmpty) _ensureSearchIndex();
  }

  List<AdhkarCategory> _filteredCategories(String q) {
    final norm = q.replaceAll(RegExp(r'[أإآ]'), 'ا');
    return _searchCats.where((c) {
      final t = c.title.replaceAll(RegExp(r'[أإآ]'), 'ا');
      return t.contains(norm);
    }).toList();
  }

  List<Dhikr> _filteredDhikr(String q) {
    final norm = q.replaceAll(RegExp(r'[أإآ]'), 'ا');
    return _searchDhikr.where((d) {
      final t = d.text.replaceAll(RegExp(r'[أإآ]'), 'ا');
      return t.contains(norm);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار'),
        actions: [
          IconButton(
            tooltip: 'إضافة فئات من أذكار أخرى',
            icon: const Icon(Icons.add),
            onPressed: _openAddFromOther,
          ),
        ],
      ),
      body: _loaded
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث عن فئة أو ذكر… مثل: أذكار دخول المسجد',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                if (!searching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    child: Text(
                      'اسحب القسم لإعادة ترتيبه كما تريد',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                Expanded(
                  child: searching
                      ? _buildSearchResults()
                      : ReorderableListView.builder(
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
                              onPin:
                                  pinnable ? () => _togglePin(entry.key) : null,
                              onTap: () => _open(entry),
                            );
                          },
                        ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPersonalList,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.bookmark_add_outlined),
        label: const Text('أذكاري'),
      ),
    );
  }

  Widget _buildSearchResults() {
    final cats = _filteredCategories(_query);
    final dhikrList = _filteredDhikr(_query).take(100).toList();
    if (cats.isEmpty && dhikrList.isEmpty) {
      return const Center(child: Text('لا توجد نتائج مطابقة'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
      children: [
        if (cats.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text('فئات مطابقة',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          ...cats.map((c) {
            final isHisn = c.book == 'حصن المسلم';
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      (isHisn ? AppTheme.primaryGreen : AppTheme.gold)
                          .withOpacity(0.15),
                  child: Icon(isHisn ? Icons.menu_book : Icons.auto_stories,
                      size: 20,
                      color: isHisn ? AppTheme.primaryGreen : AppTheme.gold),
                ),
                title: Text(c.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${c.book} — ${c.items.length} أذكار',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdhkarListScreen(
                        categoryKey: c.key, title: c.title, category: c),
                  ),
                ),
              ),
            );
          }),
        ],
        if (dhikrList.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text('أذكار مطابقة',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          ...dhikrList.map((d) => DhikrCard(dhikr: d)),
        ],
      ],
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
  final AdhkarCategory? category;
  const _AdhkarEntry(
      {required this.key,
      required this.title,
      required this.icon,
      this.category});
}