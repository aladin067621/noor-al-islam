import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../utils/theme.dart';

/// نافذة تغيير الموقع: تحديث من GPS أو اختيار مدينة يدويًا.
/// تُستخدم من شاشات المواقيت والقبلة (وممكن أي مكان آخر).
Future<void> showLocationPicker(BuildContext context) async {
  final service = LocationService.instance;

  final choice = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('تغيير الموقع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.my_location, color: AppTheme.primaryGreen),
            title: const Text('تحديث الموقع الحالي (GPS)'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.pop(context, 'gps'),
          ),
          ListTile(
            leading: const Icon(Icons.location_city, color: AppTheme.gold),
            title: const Text('اختيار مدينة يدويًا'),
            subtitle: const Text('يُحسب من إحداثيات ثابتة دون إنترنت'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.pop(context, 'city'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);

  if (choice == 'gps') {
    final err = await service.refreshFromGps();
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'تم تحديث موقعك بنجاح')));
    return;
  }

  // اختيار مدينة من القائمة اليدوية
  final selected = await showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.7,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('اختر مدينتك',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: LocationService.presetCities.length,
              itemBuilder: (context, i) {
                final c = LocationService.presetCities[i];
                final isCurrent = service.saved?.source == 'manual' &&
                    service.saved?.city == c['name'];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, size: 20),
                  title: Text(c['name']!),
                  trailing: isCurrent
                      ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                      : null,
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
  if (selected == null || !context.mounted) return;
  final name = selected['name']!;
  await service.saveManual(
      double.parse(selected['lat']!), double.parse(selected['lon']!), name);
  messenger.showSnackBar(SnackBar(content: Text('تم تحديد الموقع: $name')));
}