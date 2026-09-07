import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/adhkar_category.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'adhkar_list_screen.dart';

/// المفاتيح التي تكرّر أقسام الصباح/المساء/النوم/السفر/الصلاة الموجودة أصلاً
/// كأقسام رئيسية — تُستبعد من "أذكار أخرى" لتجنّب التكرار.
const Set<String> _duplicateUniqueKeys = {
  'حصن المسلم::hisn_27', // أذكار الصباح والمساء
  'حصن المسلم::hisn_28', // أذكار النوم
  'حصن المسلم::hisn_96', // دعاء السفر
  'حصن المسلم::hisn_15', // أذكار الآذان
  'حصن المسلم::hisn_16', // دعاء الاستفتاح (صلاة)
  'حصن المسلم::hisn_25', // الأذكار بعد السلام
  'الوابل الصيب::ch286', // طرفي النهار
  'الوابل الصيب::ch294', // أذكار النوم
  'الوابل الصيب::ch312', // أذكار الأذان
  'الوابل الصيب::ch317', // أذكار الاستفتاح
  'الوابل الصيب::ch330', // الأذكار بعد السلام
};

/// شاشة "أذكار أخرى": تعرض فئات حصن المسلم والوابل الصيب معاً،
/// قابلة للبحث، مع إمكانية إضافة أي فئة إلى القائمة الرئيسية للأذكار
/// أو (في وضع انتقاء) إلى الصفحة الرئيسية.
class AdhkarSubCategoriesScreen extends StatefulWidget {
  /// وضع انتقاء من الصفحة الرئيسية: يُرجع المفاتيح المختارة عند الضغط «تم».
  final bool pickHome;
  const AdhkarSubCategoriesScreen({super.key, this.pickHome = false});

  @override
  State<AdhkarSubCategoriesScreen> createState() =>
      _AdhkarSubCategoriesScreenState();
}

class _AdhkarSubCategoriesScreenState extends State<AdhkarSubCategoriesScreen> {
  List<AdhkarCategory> _categories = [];
  bool _loaded = false;
  String _query = '';

  // في وضع انتقاء الرئيسية: المفاتيح المختارة
  late Set<String> _selectedHome = widget.pickHome ? {} : <String>{};

  // في الوضع العادي: مفاتيح الفئات المضافة بالفعل إلى القائمة الرئيسية
  Set<String> _inMainExtra = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hisn = await DataService.instance.loadHisnCategories();
    final wabil = await DataService.instance.loadWabilCategories();
    final otherDhikr = await DataService.instance.loadAdhkar('other');
    final otherCat = AdhkarCategory(
      key: 'other_misc',
      title: 'أذكار أخرى (متنوعة)',
      items: otherDhikr,
      book: 'أذكار متنوعة',
    );
    final all = [otherCat, ...hisn, ...wabil]
        .where((c) => !_duplicateUniqueKeys.contains(c.uniqueKey))
        .toList();

    final prefs = await SharedPreferences.getInstance();
    _inMainExtra =
        (prefs.getStringList(AppConstants.keyAdhkarMainExtra) ?? []).toSet();
    if (widget.pickHome) {
      _selectedHome =
          (prefs.getStringList(AppConstants.keyHomeExtraDhikr) ?? []).toSet();
    }

    // طبق الترتيب المحفوظ إن وُجد
    final stored = prefs.getStringList(AppConstants.keySubAdhkarOrder) ?? [];
    final List<AdhkarCategory> ordered;
    if (stored.isNotEmpty) {
      final byKey = {for (final c in all) c.uniqueKey: c};
      ordered = <AdhkarCategory>[];
      for (final k in stored) {
        final c = byKey[k];
        if (c != null && !ordered.any((x) => x.uniqueKey == k)) ordered.add(c);
      }
      for (final c in all) {
        if (!ordered.any((x) => x.uniqueKey == c.uniqueKey)) ordered.add(c);
      }
    } else {
      ordered = all;
    }
    if (mounted) {
      setState(() {
        _categories = ordered;
        _loaded = true;
      });
    }
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

  /// إضافة/إزالة فئة إلى القائمة الرئيسية للأذكار (شاشة «الأذكار»)
  Future<void> _toggleMainExtra(AdhkarCategory cat) async {
    setState(() {
      if (_inMainExtra.contains(cat.uniqueKey)) {
        _inMainExtra.remove(cat.uniqueKey);
      } else {
        _inMainExtra.add(cat.uniqueKey);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        AppConstants.keyAdhkarMainExtra, _inMainExtra.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_inMainExtra.contains(cat.uniqueKey)
              ? 'أُضيف «${cat.title}» إلى قائمة الأذكار'
              : 'أُزيل «${cat.title}» من قائمة الأذكار'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// في وضع انتقاء الرئيسية: إضافة/إزالة من الاختيار المؤقت
  void _toggleHomeSelection(AdhkarCategory cat) {
    setState(() {
      if (_selectedHome.contains(cat.uniqueKey)) {
        _selectedHome.remove(cat.uniqueKey);
      } else {
        _selectedHome.add(cat.uniqueKey);
      }
    });
  }

  Future<void> _confirmHomeSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        AppConstants.keyHomeExtraDhikr, _selectedHome.toList());
    if (mounted) Navigator.pop(context, _selectedHome.toList());
  }

  void _openCategory(AdhkarCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdhkarListScreen(
            categoryKey: category.key,
            title: category.title,
            category: category),
      ),
    );
  }

  /// فتح قائمة الفئات المضافة إلى القائمة الرئيسية للأذكار
  void _openMainExtra() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdhkarListScreen(
          categoryKey: 'main_extra',
          title: 'الفئات المضافة إلى قائمة الأذكار',
        ),
      ),
    );
  }

  List<AdhkarCategory> get _filtered {
    final q = _query.trim();
    if (q.isEmpty) return _categories;
    final norm = q.replaceAll(RegExp(r'[أإآ]'), 'ا');
    return _categories.where((c) {
      final title = c.title.replaceAll(RegExp(r'[أإآ]'), 'ا');
      if (title.contains(norm)) return true;
      // بحث داخل نصوص الأذكار في نفس الفئة
      return c.items.any((d) {
        final t = d.text.replaceAll(RegExp(r'[أإآ]'), 'ا');
        return t.contains(norm);
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickHome ? 'أضف أذكارًا للرئيسية' : 'أذكار أخرى'),
        actions: [
          if (widget.pickHome)
            TextButton(
              onPressed: _selectedHome.isEmpty ? null : _confirmHomeSelection,
              child: const Text('تم'),
            ),
        ],
      ),
      floatingActionButton: widget.pickHome
          ? null
          : FloatingActionButton.extended(
              heroTag: 'adhkar_more',
              onPressed: _openMainExtra,
              icon: const Icon(Icons.favorite),
              label: Text('${_inMainExtra.length} بقائمة الأذكار'),
            ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث عن فئة أو ذكر… مثل: دخول المسجد',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (q) => setState(() => _query = q),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final category = _filtered[index];
        final isHisn = category.book == 'حصن المسلم';
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isHisn ? AppTheme.primaryGreen : AppTheme.gold)
                  .withOpacity(0.15),
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
            trailing: widget.pickHome
                ? Checkbox(
                    value: _selectedHome.contains(category.uniqueKey),
                    onChanged: (_) => _toggleHomeSelection(category),
                  )
                : IconButton(
                    tooltip: _inMainExtra.contains(category.uniqueKey)
                        ? 'أزل من قائمة الأذكار'
                        : 'أضف إلى قائمة الأذكار',
                    icon: Icon(
                      _inMainExtra.contains(category.uniqueKey)
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: _inMainExtra.contains(category.uniqueKey)
                          ? AppTheme.primaryGreen
                          : null,
                    ),
                    onPressed: () => _toggleMainExtra(category),
                  ),
            onTap: () => widget.pickHome
                ? _toggleHomeSelection(category)
                : _openCategory(category),
          ),
        );
      },
    );
  }
}