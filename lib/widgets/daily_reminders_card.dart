import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// قسم التذكيرات اليومية (سورة الكهف + صيام الاثنين/الخميس + الأيام البيض)
/// يعرض في الصفحة الرئيسية في الزيارة الأولى فقط، وهو متاح دائماً في الإعدادات.
class DailyRemindersCard extends StatefulWidget {
  const DailyRemindersCard({super.key});

  @override
  State<DailyRemindersCard> createState() => _DailyRemindersCardState();
}

class _DailyRemindersCardState extends State<DailyRemindersCard> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(AppConstants.keySunnahReminders) ?? true;
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  Future<void> _toggle(bool value) async {
    if (!mounted) return;
    setState(() => _enabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keySunnahReminders, value);
    if (value) {
      NotificationService.instance.scheduleSunnahReminders();
    } else {
      NotificationService.instance.cancelSunnahReminders();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('تم إيقاف تذكيرات السنن اليومية')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active,
                    color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'التذكيرات اليومية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Switch(value: _enabled, onChanged: _toggle),
              ],
            ),
            const Divider(height: 8),
            const _ReminderRow(
              icon: Icons.menu_book,
              day: 'الجمعة',
              title: 'قراءة سورة الكهف',
              hadith: '«من قرأ سورة الكهف يوم الجمعة أضاء له من النور ما بين الجمعتين»',
              source: 'رواه الحاكم والبيهقي، وصححه الألباني',
            ),
            const _ReminderRow(
              icon: Icons.restaurant,
              day: 'الاثنين والخميس',
              title: 'صيام مندوب — من الأفضل الصيام فيهما',
              hadith: '«تُعرَض الأعمال يوم الاثنين والخميس، فأحب أن يُعرَض عملي وأنا صائم»',
              source: 'رواه الترمذي وابن ماجه، وحسّنه الترمذي',
            ),
            const _ReminderRow(
              icon: Icons.dark_mode,
              day: 'الأيام البيض',
              title: 'الصيام 13/14/15 من كل شهر هجري',
              hadith: '«يا أبا ذرّ، إذا صُمتَ من الشهر ثلاثةَ أيامٍ فصُم ثلاثَ عشرةَ وأربعَ عشرةَ وخمسَ عشرةَ»',
              source: 'رواه الترمذي والنسائي، وحسّنه الترمذي',
              secondaryHadith: '«صيام ثلاثة أيام من كل شهر صيام الدهر»',
              secondarySource: 'رواه أحمد والدارمي',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final IconData icon;
  final String day;
  final String title;
  final String hadith;
  final String source;
  final String? secondaryHadith;
  final String? secondarySource;

  const _ReminderRow({
    required this.icon,
    required this.day,
    required this.title,
    required this.hadith,
    required this.source,
    this.secondaryHadith,
    this.secondarySource,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.gold.withOpacity(0.15),
            child: Icon(icon, size: 18, color: AppTheme.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$day — $title',
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  hadith,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.grey[800],
                    fontFamily: AppTheme.quranFontFamily,
                  ),
                ),
                if (secondaryHadith != null)
                  Text(
                    secondaryHadith!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.grey[800],
                      fontFamily: AppTheme.quranFontFamily,
                    ),
                  ),
                Text(
                  '($source)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (secondarySource != null)
                  Text(
                    '($secondarySource)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}