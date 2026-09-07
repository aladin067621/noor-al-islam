import 'dart:async';

import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../utils/theme.dart';

/// نافذة تغيير الموقع: تحديث من GPS، أو البحث عن أي مدينة (عبر الإنترنت)،
/// أو الاختيار من القائمة المحفوظة مع إمكانية الإدخال اليدوي.
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
            leading: const Icon(Icons.search, color: AppTheme.gold),
            title: const Text('البحث عن مدينة'),
            subtitle: const Text('يبحث في جميع مدن العالم عبر الإنترنت'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.pop(context, 'city'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_location_alt, color: AppTheme.primaryGreen),
            title: const Text('إدخال الإحداثيات يدويًا'),
            subtitle: const Text('خط العرض وخط الطول مباشرة'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.pop(context, 'manual'),
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

  if (choice == 'manual') {
    final ok = await showManualEntry(context);
    if (ok != null && context.mounted) {
      messenger.showSnackBar(
          SnackBar(content: Text('تم تحديد الموقع يدويًا: ${ok.label}')));
    }
    return;
  }

  // بحث عن مدينة عبر الإنترنت + قائمة سريعة للمدن الرئيسية
  final selected = await showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.8,
      child: _CitySearchSheet(service: service),
    ),
  );
  if (selected == null || !context.mounted) return;
  final name = selected['name']!;
  await service.saveManual(
      double.parse(selected['lat']!), double.parse(selected['lon']!), name);
  messenger.showSnackBar(SnackBar(content: Text('تم تحديد الموقع: $name')));
}

/// ورقة البحث عن مدينة: حقل بحث يستعلم Open-Meteo، مع قسم للمدن المحفوظة.
class _CitySearchSheet extends StatefulWidget {
  final LocationService service;
  const _CitySearchSheet({required this.service});

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _searching = false;
  bool _searched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _results = LocationService.presetCities
        .map((c) => {...c, 'label': c['name']!})
        .toList();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search());
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = LocationService.presetCities
            .map((c) => {...c, 'label': c['name']!})
            .toList();
        _searched = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searched = true;
    });
    final found = await widget.service.searchCities(q);
    if (!mounted) return;
    setState(() {
      _results = found;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('اختر مدينتك',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'ابحث عن مدينة، مثل: صنعاء، كوناكري، كراتشي...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _results.isEmpty
              ? Center(
                  child: Text(
                    _searching
                        ? 'جارِ البحث...'
                        : _searched
                            ? 'لم يتم العثور على نتائج'
                            : 'اكتب اسم المدينة للبحث، أو اختر من المدن الرئيسية أدناه',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final c = _results[i];
                    final isCurrent = service.saved?.source == 'manual' &&
                        service.saved?.city == c['name'];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined, size: 20),
                      title: Text(c['name']!),
                      subtitle: c['sub'] != null && c['sub']!.isNotEmpty
                          ? Text(c['sub']!, style: const TextStyle(fontSize: 11))
                          : null,
                      trailing: isCurrent
                          ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                          : null,
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// نافذة إدخال الإحداثيات يدويًا — تُرجع SavedLocation أو null إن أُلغيت.
Future<SavedLocation?> showManualEntry(BuildContext context) async {
  final latController = TextEditingController();
  final lonController = TextEditingController();
  final nameController = TextEditingController();

  final saved = await showDialog<SavedLocation>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('إدخال الإحداثيات يدويًا'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المدينة (اختياري)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'خط العرض (Latitude)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lonController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'خط الطول (Longitude)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final lat = double.tryParse(latController.text.trim());
            final lon = double.tryParse(lonController.text.trim());
            if (lat == null || lon == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('أدخل قيمًا صحيحة لخط العرض وخط الطول')),
              );
              return;
            }
            Navigator.pop(
              context,
              SavedLocation(
                latitude: lat,
                longitude: lon,
                city: nameController.text.trim(),
                source: 'manual',
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );

  if (saved != null) {
    await LocationService.instance
        .saveManual(saved.latitude, saved.longitude, saved.city);
  }
  return saved;
}