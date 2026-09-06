import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../models/dhikr.dart';
import '../../services/data_service.dart';
import '../../services/personal_adhkar_service.dart';
import '../../utils/theme.dart';
import '../../widgets/dhikr_card.dart';

/// شاشة "أذكاري": قائمة شخصية من مراجع الأذكار.
/// تُخزَّن المفاتيح المرجعية فقط، ويُعرض نص كل ذكر مباشرة من مصدره
/// دون نسخ البيانات، فأي تعديل لاحق على المصدر ينعكس تلقائياً.
class AdhkarPersonalListScreen extends StatefulWidget {
  const AdhkarPersonalListScreen({super.key});

  @override
  State<AdhkarPersonalListScreen> createState() =>
      _AdhkarPersonalListScreenState();
}

class _AdhkarPersonalListScreenState extends State<AdhkarPersonalListScreen> {
  Map<String, Dhikr> _byRef = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = await DataService.instance.loadAllAdhkarByRefKey();
    if (mounted) {
      setState(() {
        _byRef = map;
        _loading = false;
      });
    }
  }

  void _showFullDhikr(Dhikr dhikr) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  '${dhikr.source}\n${dhikr.category ?? ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              DhikrCard(dhikr: dhikr),
            ],
          ),
        ),
      ),
    );
  }

  void _copyAll(List<Dhikr> items) {
    final text = items.map((d) => d.shareText()).join('\n\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ جميع أذكاري'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PersonalAdhkarService>();
    final refs = service.refKeys;
    final items = refs.map((r) => _byRef[r]).whereType<Dhikr>().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('أذكاري'),
        actions: [
          if (items.length > 1)
            IconButton(
              tooltip: 'نسخ جميع أذكاري',
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: () => _copyAll(items),
            ),
        ],
      ),
      body: !_loading
          ? items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_add_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('لا شيء في أذكاري بعد',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        'اضغط أيقونة الإشارة المرجعية أسفل أي بطاقة ذكر لإضافته هنا',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: items.length,
                  onReorder: service.move,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    final dhikr = items[index];
                    return Card(
                      key: ValueKey(dhikr.refKey),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: ListTile(
                        title: Text(
                          dhikr.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: AppTheme.quranFontFamily,
                            fontSize: 16,
                            height: 1.8,
                          ),
                        ),
                        subtitle: Text(
                          dhikr.source,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'إزالة من أذكاري',
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () => service.remove(dhikr.refKey),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.drag_handle,
                                    color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showFullDhikr(dhikr),
                      ),
                    );
                  },
                )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}