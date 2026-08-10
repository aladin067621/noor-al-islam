// اختبار بسيط للتأكد من إقلاع التطبيق وعرض الشاشة الرئيسية
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:islamic_app/app.dart';
import 'package:islamic_app/services/settings_provider.dart';
import 'package:islamic_app/services/favorites_service.dart';

void main() {
  testWidgets('يقلع التطبيق ويعرض الشاشة الرئيسية', (WidgetTester tester) async {
    final settings = SettingsProvider();
    final favorites = FavoritesService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<FavoritesService>.value(value: favorites),
        ],
        child: const IslamicApp(),
      ),
    );

    // إطار واحد على الأقل دون أخطاء بناء
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
