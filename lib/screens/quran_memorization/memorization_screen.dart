import 'package:flutter/material.dart';
import '../../services/hifz_service.dart';
import '../../services/quran_audio_service.dart';
import 'hifz_memorization_tab.dart';
import 'hifz_mushaf_tab.dart';
import 'hifz_progress_tab.dart';
import 'hifz_settings_sheet.dart';
import 'hifz_test_tab.dart';
import 'hifz_widgets.dart';

/// قسم حفظ القرآن — مصحف (قراءة/تجويد) + جلسة حفظ + تسميع ذاتي + تقدم.
class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  @override
  void initState() {
    super.initState();
    HifzService.instance.load();
    QuranAudioService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حفظ القرآن'),
          actions: [
            IconButton(
              tooltip: 'إعدادات الحفظ والتلاوة',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => showHifzSettingsSheet(context),
            ),
          ],
        ),
        body: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'المصحف'),
                Tab(text: 'الحفظ'),
                Tab(text: 'التسميع'),
                Tab(text: 'التقدم'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  HifzMushafTab(),
                  HifzMemorizationTab(),
                  HifzTestTab(),
                  HifzProgressTab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const PlayerBar(),
      ),
    );
  }
}