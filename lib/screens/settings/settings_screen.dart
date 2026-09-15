import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/daily_reminders_card.dart';

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
          _header('التذكيرات اليومية'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'تذكيرات السنن اليومية: سورة الكهف يوم الجمعة، وصيام الاثنين والخميس، والأيام البيض.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          const DailyRemindersCard(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'هذا القسم يظهر في الصفحة الرئيسية في أول زيارة فقط، وهو متاح دائماً هنا.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Divider(),
          _header('الأذكار المنبثقة'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('تفعيل الأذكار المنبثقة'),
            subtitle: const Text('تنبيه دوري بذكر عشوائي: داخل التطبيق جانبي صامت وخارجه إشعار نظام'),
            value: s.popupEnabled,
            onChanged: (v) {
              s.setPopupEnabled(v);
              if (!v) NotificationService.instance.cancelPopupDhikr();
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('فترة الأذكار المنبثقة'),
            subtitle: Text('كل ${s.popupInterval} دقيقة'),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => _editPopupInterval(context, s),
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
              'ملاحظة: تذكيرات أذكار الصباح والمساء والسنن اليومية إشعارات نظام. '
              'أما الأذكار المنبثقة فتنبيه داخلي جانبي بصمت داخل التطبيق، '
              'وعند مغادرة التطبيق يُرسل إشعار نظام تذكيرًا دون فتح التطبيق.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const Divider(),
          _header('الخلفية والبطارية'),
          ListTile(
            leading: const Icon(Icons.battery_charging_full),
            title: const Text('إيقاف تقييد البطارية'),
            subtitle: const Text(
                'لكي تصل التذكيرات والأذكار وأنت خارج التطبيق، اجعل الاستخدام دون تقييد (غير محدود)'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openBatterySettings(context),
          ),
        ],
      ),
    );
  }

  /// فتح شاشة إعدادات البطارية في النظام — مع بديل إرشادي عند تعذّر الفتح
  Future<void> _openBatterySettings(BuildContext ctx) async {
    const uri =
        'intent:#Intent;action=android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS;end';
    try {
      if (await canLaunchUrl(Uri.parse(uri))) {
        await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text(
          'من إعدادات الهاتف: البطارية ← البطارية غير المحدودة '
          '(أو تحسين البطارية) ← العروة الوثقى ← لا تقييد',
        ),
        duration: Duration(seconds: 6),
      ));
    }
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

  Future<void> _editPopupInterval(BuildContext context, SettingsProvider s) async {
    final controller =
        TextEditingController(text: '${s.popupInterval}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فترة الأذكار المنبثقة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: 'عدد الدقائق بين كل ذكر وآخر',
            hintText: 'مثال: 30 أو 60 أو 1000',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            final n = int.tryParse(v.trim());
            if (n != null && n > 0) Navigator.pop(ctx, n);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              if (n != null && n > 0) {
                Navigator.pop(ctx, n);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('أدخل رقمًا صحيحًا بالدقائق')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await s.setPopupInterval(result);
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
