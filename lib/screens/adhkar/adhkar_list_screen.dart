import 'package:flutter/material.dart';
import '../../models/dhikr.dart';
import '../../services/data_service.dart';
import '../../widgets/dhikr_card.dart';

class AdhkarListScreen extends StatelessWidget {
  final String categoryKey;
  final String title;

  const AdhkarListScreen({super.key, required this.categoryKey, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<Dhikr>>(
        future: DataService.instance.loadAdhkar(categoryKey),
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
