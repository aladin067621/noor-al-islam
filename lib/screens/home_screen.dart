import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hijri/hijri_calendar.dart';

import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/card_item.dart';
import '../widgets/app_drawer.dart';
import '../services/data_service.dart';

import 'adhkar/adhkar_categories_screen.dart';
import 'tasbih/tasbih_screen.dart';
import 'asma_al_husna/asma_al_husna_screen.dart';
import 'prayer/prayer_screen.dart';
import 'prayer/prayer_times_screen.dart';
import 'qibla/qibla_screen.dart';
import 'hijri_calendar/hijri_calendar_screen.dart';
import 'tawheed/tawheed_screen.dart';
import 'pillars/pillars_screen.dart';
import 'quran_tafsir/tafsir_surahs_screen.dart';
import 'library/books_list_screen.dart';
import 'quran_memorization/memorization_screen.dart';
import 'favorites/favorites_screen.dart';
import 'notes/notes_screen.dart';
import 'search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _verses = [];
  int _verseIndex = 0;
  Timer? _timer;

  static const List<String> _hijriMonths = [
    '', 'محرّم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
    'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];

  String _hijriDateStr() {
    final hijri = HijriCalendar.now();
    final monthName = _hijriMonths[hijri.hMonth];
    return '${hijri.hDay} $monthName ${hijri.hYear}';
  }

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    final config = await DataService.instance.loadConfig();
    final list = (config['rotatingVerses'] as List?)?.cast<String>() ?? [];
    if (!mounted) return;
    setState(() => _verses = list);
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_verses.isEmpty || !mounted) return;
      setState(() => _verseIndex = (_verseIndex + 1) % _verses.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _open(BuildContext context, String id) {
    Widget? screen;
    switch (id) {
      case 'adhkar':
        screen = const AdhkarCategoriesScreen();
        break;
      case 'tasbih':
        screen = const TasbihScreen();
        break;
      case 'asma':
        screen = const AsmaAlHusnaScreen();
        break;
      case 'prayer':
        screen = const PrayerScreen();
        break;
      case 'prayer_times':
        screen = const PrayerTimesScreen();
        break;
      case 'qibla':
        screen = const QiblaScreen();
        break;
      case 'hijri':
        screen = const HijriCalendarScreen();
        break;
      case 'tawheed':
        screen = const TawheedScreen();
        break;
      case 'pillars':
        screen = const PillarsScreen();
        break;
      case 'tafsir':
        screen = const TafsirSurahsScreen();
        break;
      case 'library':
        screen = const BooksListScreen();
        break;
      case 'memorization':
        screen = const MemorizationScreen();
        break;
      case 'favorites':
        screen = const FavoritesScreen();
        break;
      case 'notes':
        screen = const NotesScreen();
        break;
      case 'search':
        screen = const SearchScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  Future<void> _openTelegram() async {
    final config = await DataService.instance.loadConfig();
    final uri = Uri.parse(config['telegramUrl'] ?? AppConstants.telegramUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'القائمة',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_hijriDateStr()),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                  ),
                ),
                 child: Padding(
                   padding: const EdgeInsets.fromLTRB(28, 62, 28, 20),
                   child: Align(
                     alignment: Alignment.topCenter,
                     child: SizedBox(
                       height: 58,
                       width: double.infinity,
                     child: AnimatedSwitcher(
                         duration: const Duration(milliseconds: 500),
                         layoutBuilder: (currentChild, previousChildren) =>
                             Stack(
                           alignment: Alignment.topCenter,
                           children: [
                             ...previousChildren,
                             if (currentChild != null) currentChild,
                           ],
                         ),
                         child: Text(
                           _verses.isEmpty ? '' : _verses[_verseIndex],
                           key: ValueKey(_verseIndex),
                           textAlign: TextAlign.right,
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(
                             color: Colors.white,
                             fontFamily: AppTheme.quranFontFamily,
                             fontSize: 16,
                             height: 1.6,
                           ),
                         ),
                       ),
                     ),
                   ),
                 ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final section = homeSections[index];
                  return CardItem(
                    section: section,
                    onTap: () => _open(context, section.id),
                  );
                },
                childCount: homeSections.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.send, color: AppTheme.primaryGreen),
                  title: const Text('قناة تيليجرام'),
                  subtitle: const Text('انضم إلينا للمزيد من الفائدة'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openTelegram,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
