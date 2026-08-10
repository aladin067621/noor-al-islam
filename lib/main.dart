import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/settings_provider.dart';
import 'services/favorites_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsProvider();
  await settings.load();

  final favorites = FavoritesService();
  await favorites.load();

  // تهيئة الإشعارات المحلية (لا تعطّل التشغيل إن فشلت على المنصات غير المدعومة)
  await NotificationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: favorites),
      ],
      child: const IslamicApp(),
    ),
  );
}
