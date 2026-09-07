import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/dhikr.dart';
import '../../models/adhkar_category.dart';
import '../../services/data_service.dart';
import '../../utils/constants.dart';
import '../../widgets/dhikr_card.dart';

class AdhkarListScreen extends StatelessWidget {
  final String categoryKey;
  final String title;
  final AdhkarCategory? category;

  const AdhkarListScreen(
      {super.key,
      required this.categoryKey,
      required this.title,
      this.category});

  Future<List<Dhikr>> _load() {
    if (category != null) {
      return Future.value(category!.items);
    }
    if (categoryKey == 'hisn_all') {
      return DataService.instance.loadHisnAdhkar();
    }
    if (categoryKey == 'wabil_all') {
      return DataService.instance.loadWabilAdhkar();
    }
    if (categoryKey == 'main_extra') {
      return _loadMainExtra();
    }
    return DataService.instance.loadAdhkar(categoryKey);
  }

  /// الأذكار من الفئات المضافة إلى القائمة الرئيسية من «أذكار أخرى»
  Future<List<Dhikr>> _loadMainExtra() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getStringList(AppConstants.keyAdhkarMainExtra) ?? [];
    if (keys.isEmpty) return const [];
    final catMap = await DataService.instance.loadHisnWabilCategoriesByKey();
    final result = <Dhikr>[];
    for (final uk in keys) {
      final c = catMap[uk];
      if (c == null) continue;
      for (final d in c.items) {
        if (!result.any((x) => x.refKey == d.refKey)) result.add(d);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<Dhikr>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل الأذكار: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد أذكار'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) => DhikrCard(dhikr: items[index]),
          );
        },
      ),
    );
  }
}
