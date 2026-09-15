import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/settings_provider.dart';
import 'services/favorites_service.dart';
import 'services/personal_adhkar_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة خدمة الأذان الأمامية (أندرويد فقط)
  _initAdhanForegroundTask();

  final settings = SettingsProvider();
  await settings.load();

  final favorites = FavoritesService();
  await favorites.load();

  final personalAdhkar = PersonalAdhkarService();
  await personalAdhkar.load();

  // تهيئة الإشعارات المحلية (لا تعطّل التشغيل إن فشلت على المنصات غير المدعومة)
  await NotificationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: favorites),
        ChangeNotifierProvider.value(value: personalAdhkar),
      ],
      child: const IslamicApp(),
    ),
  );
}

/// تهيئة خدمة الأذان الأمامية على أندرويد (لا تُعطّل التشغيل على غيره).
void _initAdhanForegroundTask() {
  if (!Platform.isAndroid) return;
  FlutterForegroundTask.initCommunicationPort();
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'adhan_foreground',
      channelName: 'الأذان الخلفي',
      channelDescription: 'يبقى التطبيق يراقب مواقيت الصلاة ويعمل الأذان عند دخول الوقت',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      enableVibration: false,
      playSound: false,
      showWhen: false,
      showBadge: false,
      onlyAlertOnce: true,
      visibility: NotificationVisibility.VISIBILITY_PUBLIC,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(60000),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );
}
