import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          _header('العرض'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('الوضع الليلي'),
            value: s.darkMode,
            onChanged: s.setDarkMode,
          ),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('حجم الخط'),
            subtitle: Slider(
              min: AppConstants.minFontSize,
              max: AppConstants.maxFontSize,
              divisions: (AppConstants.maxFontSize - AppConstants.minFontSize).toInt(),
              label: s.fontSize.toStringAsFixed(0),
              value: s.fontSize,
              onChanged: s.setFontSize,
            ),
            trailing: Text(s.fontSize.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(),
          _header('تذكير الأذكار'),
          _reminderTile(
            context,
            icon: Icons.wb_sunny,
            title: 'تذكير أذكار الصباح',
            enabled: s.morningReminder,
            time: s.morningTime,
            onToggle: (v) async {
              final time = s.parseTime(s.morningTime);
              await s.setMorningReminder(v);
              if (v) {
                await NotificationService.instance.scheduleMorning(time);
              } else {
                await NotificationService.instance.cancel(NotificationService.morningId);
              }
            },
            onPickTime: (picked) async {
              await s.setMorningReminder(s.morningReminder, time: s.formatTime(picked));
              if (s.morningReminder) {
                await NotificationService.instance.scheduleMorning(picked);
              }
            },
          ),
          _reminderTile(
            context,
            icon: Icons.nightlight_round,
            title: 'تذكير أذكار المساء',
            enabled: s.eveningReminder,
            time: s.eveningTime,
            onToggle: (v) async {
              final time = s.parseTime(s.eveningTime);
              await s.setEveningReminder(v);
              if (v) {
                await NotificationService.instance.scheduleEvening(time);
              } else {
                await NotificationService.instance.cancel(NotificationService.eveningId);
              }
            },
            onPickTime: (picked) async {
              await s.setEveningReminder(s.eveningReminder, time: s.formatTime(picked));
              if (s.eveningReminder) {
                await NotificationService.instance.scheduleEvening(picked);
              }
            },
          ),
          const Divider(),
          _header('الأذكار المنبثقة'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('تفعيل الأذكار المنبثقة'),
            subtitle: const Text('إشعار دوري بذكر عشوائي من قائمتك'),
            value: s.popupEnabled,
            onChanged: (v) async {
              await s.setPopupEnabled(v);
              if (v) {
                await NotificationService.instance.showRandomDhikr(s.popupAdhkar);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('فترة الأذكار المنبثقة'),
            trailing: DropdownButton<int>(
              value: s.popupInterval,
              items: const [
                DropdownMenuItem(value: 30, child: Text('كل 30 دقيقة')),
                DropdownMenuItem(value: 60, child: Text('كل ساعة')),
                DropdownMenuItem(value: 120, child: Text('كل ساعتين')),
                DropdownMenuItem(value: 180, child: Text('كل 3 ساعات')),
              ],
              onChanged: (v) {
                if (v != null) s.setPopupInterval(v);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('قائمة الأذكار المنبثقة'),
            subtitle: Text('${s.popupAdhkar.length} ذكر'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _editPopupAdhkar(context, s),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ملاحظة: تعمل الإشعارات على نظام أندرويد. قد يتطلب الأمر السماح بالإشعارات والمنبهات الدقيقة من إعدادات النظام.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: const TextStyle(
                color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14)),
      );

  Widget _reminderTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool enabled,
    required String time,
    required ValueChanged<bool> onToggle,
    required ValueChanged<TimeOfDay> onPickTime,
  }) {
    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(icon),
          title: Text(title),
          subtitle: Text('الوقت: $time'),
          value: enabled,
          onChanged: onToggle,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 72, bottom: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.access_time, size: 18),
              label: const Text('تغيير الوقت'),
              onPressed: () async {
                final parts = time.split(':');
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                      hour: int.parse(parts[0]), minute: int.parse(parts[1])),
                );
                if (picked != null) onPickTime(picked);
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editPopupAdhkar(BuildContext context, SettingsProvider s) async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('الأذكار المنبثقة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: s.popupAdhkar
                      .map((d) => Chip(
                            label: Text(d),
                            onDeleted: () async {
                              await s.removePopupDhikr(d);
                              setSheet(() {});
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'أضف ذكرًا مخصصًا...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        await s.addCustomDhikr(controller.text);
                        controller.clear();
                        setSheet(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }
}
