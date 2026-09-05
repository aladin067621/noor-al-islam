import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../models/adhkar_category.dart';
import '../../utils/theme.dart';

/// شاشة البحث والإضافة: تعرض كل الفئات المتاحة (حصن + وابل) مع خانات اختيار
/// يمكن البحث فيها، ومن ثم اختيار عدة فئات لإضافتها إلى "القائمة الإضافية".
class AdhkarPickerScreen extends StatefulWidget {
  /// مفاتيح الفئات المضافة مسبقاً (يُستبعد عرضها لأنها مضافة بالفعل)
  final Set<String> exclude;

  /// كل مفاتيح الفئات المتاحة
  final Set<String> allKeys;

  const AdhkarPickerScreen({super.key, this.exclude = const {}, this.allKeys = const {}});

  @override
  State<AdhkarPickerScreen> createState() => _AdhkarPickerScreenState();
}

class _AdhkarPickerScreenState extends State<AdhkarPickerScreen> {
  List<AdhkarCategory> _all = [];
  bool _loaded = false;
  final Set<String> _selected = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hisn = await DataService.instance.loadHisnCategories();
    final wabil = await DataService.instance.loadWabilCategories();
    if (mounted) {
      setState(() {
        _all = [...hisn, ...wabil]
            .where((c) => !widget.exclude.contains(c.uniqueKey))
            .toList();
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? _all
        : _all
            .where((c) =>
                c.title.contains(_query) || c.book.contains(_query))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة فئة')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن فئة…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      final isHisn = category.book == 'حصن المسلم';
                      final checked = _selected.contains(category.uniqueKey);
                      return Card(
                        child: CheckboxListTile(
                          value: checked,
                          secondary: CircleAvatar(
                            backgroundColor:
                                (isHisn ? AppTheme.primaryGreen : AppTheme.gold)
                                    .withOpacity(0.15),
                            child: Icon(
                              isHisn ? Icons.menu_book : Icons.auto_stories,
                              size: 18,
                              color:
                                  isHisn ? AppTheme.primaryGreen : AppTheme.gold,
                            ),
                          ),
                          title: Text(category.title,
                              style: const TextStyle(fontSize: 14.5)),
                          subtitle: Text(
                            '${category.book} — ${category.items.length} أذكار',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onChanged: (sel) {
                            setState(() {
                              if (sel == true) {
                                _selected.add(category.uniqueKey);
                              } else {
                                _selected.remove(category.uniqueKey);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.pop(context, _selected.toList()),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.check),
            label: Text('إضافة (${_selected.length})'),
          ),
        ),
      ),
    );
  }
}
