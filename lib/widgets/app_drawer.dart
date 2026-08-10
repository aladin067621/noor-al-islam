import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';
import '../utils/theme.dart';
import '../services/data_service.dart';
import '../screens/search/search_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';

/// القائمة الجانبية (Drawer)
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _openTelegram(BuildContext context) async {
    final config = await DataService.instance.loadConfig();
    final url = config['telegramUrl'] ?? AppConstants.telegramUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.mosque, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾',
                  style: TextStyle(color: Colors.white70, fontFamily: AppTheme.quranFontFamily),
                ),
              ],
            ),
          ),
          _tile(context, Icons.search, 'البحث', () => _go(context, const SearchScreen())),
          _tile(context, Icons.favorite, 'المفضلة', () => _go(context, const FavoritesScreen())),
          _tile(context, Icons.edit_note, 'الملاحظات', () => _go(context, const NotesScreen())),
          _tile(context, Icons.send, 'قناة تيليجرام', () {
            Navigator.pop(context);
            _openTelegram(context);
          }),
          const Divider(),
          _tile(context, Icons.settings, 'الإعدادات', () => _go(context, const SettingsScreen())),
          _tile(context, Icons.info_outline, 'عن التطبيق', () => _go(context, const AboutScreen())),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}
