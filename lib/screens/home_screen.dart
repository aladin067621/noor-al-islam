import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../models/dhikr.dart';
import '../models/book.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/card_item.dart';
import '../widgets/app_drawer.dart';
import '../widgets/daily_reminders_card.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';

import 'adhkar/adhkar_categories_screen.dart';
import 'adhkar/adhkar_sub_categories_screen.dart';
import 'adhkar/adhkar_list_screen.dart';
import 'asma_al_husna/asma_al_husna_screen.dart';
import 'prayer/prayer_screen.dart';
import 'prayer/prayer_times_screen.dart';
import 'qibla/qibla_screen.dart';
import 'hijri_calendar/hijri_calendar_screen.dart';
import 'tawheed/tawheed_screen.dart';
import 'pillars/pillars_screen.dart';
import 'quran_tafsir/tafsir_surahs_screen.dart';
import 'library/books_list_screen.dart';
import 'library/book_chapters_screen.dart';
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
  bool _showDailyReminders = true;

  List<String> _adhkarTexts = [];
  List<String> _pinnedAdhkar = [];
  List<HomeSection> _sections = [];
  List<HomeSection> _hiddenSections = [];
  bool _editMode = false;

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
    _loadAdhkarTexts();
    _loadPinned();
    _loadSections();
    _loadReminderVisibility();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowFirstLaunchDialog());
  }

  /// التذكيرات اليومية تظهر في الصفحة الرئيسية في الزيارة الأولى فقط،
  /// ثم تبقى متاحة من الإعدادات.
  Future<void> _loadReminderVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(AppConstants.keyDailyRemindersSeen) ?? false;
    if (!seen) {
      await prefs.setBool(AppConstants.keyDailyRemindersSeen, true);
    }
    if (!mounted) return;
    setState(() => _showDailyReminders = !seen);
  }

  /// نافذة طلب الأذونات عند أول استخدام للتطبيق (الإشعارات + الموقع)
  Future<void> _maybeShowFirstLaunchDialog() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConstants.keyFirstLaunchDone) ?? false) return;
    await prefs.setBool(AppConstants.keyFirstLaunchDone, true);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل الأذونات'),
        content: const Text(
          'لكي يعمل التطبيق بالشكل الصحيح:\n'
          '• السماح بالإشعارات: تذكيرك بالأذكار والسنن اليومية.\n'
          '• السماح بتحديد الموقع: مواقيت الصلاة واتجاه القبلة.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _grantPermissions();
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  Future<void> _grantPermissions() async {
    try {
      await NotificationService.instance.requestNotificationPermission();
    } catch (_) {}
    try {
      await NotificationService.instance.requestExactAlarmsPermission();
    } catch (_) {}
    try {
      await Geolocator.requestPermission();
    } catch (_) {}
    await NotificationService.instance.scheduleSunnahReminders();
  }

  Future<void> _loadVerses() async {
    final config = await DataService.instance.loadConfig();
    final list = (config['rotatingVerses'] as List?)?.cast<String>() ?? [];
    if (!mounted) return;
    setState(() => _verses = list);
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final total = _currentTexts().length;
      if (total == 0) return;
      setState(() => _verseIndex = (_verseIndex + 1) % total);
    });
  }

  // القائمة الحالية للنصوص الدوّارة (تفضيل الأذكار ثم الأدعية)
  List<String> _currentTexts() =>
      _adhkarTexts.isNotEmpty ? _adhkarTexts : _verses;

  String _displayedText() {
    final list = _currentTexts();
    if (list.isEmpty) return '';
    return list[_verseIndex % list.length];
  }

  int _textKey() {
    final list = _currentTexts();
    if (list.isEmpty) return 0;
    final idx = _verseIndex % list.length;
    return '$idx::${list[idx]}'.hashCode;
  }

  /// تحميل نصوص أذكار دوّارة قصيرة (من أذكار الصباح والمساء) لعرضها في العنوان
  Future<void> _loadAdhkarTexts() async {
    try {
      final morning = await DataService.instance.loadAdhkar('morning');
      final evening = await DataService.instance.loadAdhkar('evening');
      final texts = [...morning, ...evening]
          .map((d) => d.text)
          .where((t) => t.isNotEmpty && t.length <= 90)
          .toList();
      if (!mounted) return;
      setState(() => _adhkarTexts = texts);
    } catch (_) {
      // تجاهل — لا نريد كسر الشاشة إذا فشل التحميل
    }
  }

  /// تحميل الأقسام المثبّتة في الصفحة الرئيسية
  Future<void> _loadPinned() async {
    final prefs = await SharedPreferences.getInstance();
    final pinned =
        prefs.getStringList(AppConstants.keyPinnedAdhkar) ?? [];
    if (!mounted) return;
    setState(() => _pinnedAdhkar = pinned);
  }

  /// تحميل الأقسام الظاهرة في الصفحة الرئيسية مع المخفية (ترحيل من ترتيب v1.0.27)
  Future<void> _loadSections() async {
    final prefs = await SharedPreferences.getInstance();
    // أقسام ديناميكية: فئات «أذكار أخرى» المضافة من وضع التعديل
    final dynamicSections = await _loadDhikrHomeSections();
    // بناء خريطة لجميع الأقسام: الأصلية + الإضافية (أذكار) + الديناميكية
    final allSections = [
      ...homeSections,
      ...extraAdhkarHomeSections,
      ...dynamicSections,
    ];
    final byId = {for (final s in allSections) s.id: s};

    // القائمة الافتراضية: الأقسام الأصلية فقط (بدون أذكار إضافية)
    final defaults = homeSections.map((s) => s.id).toList();
    List<String> stored;
    final bool fromDefault;
    final saved = prefs.getStringList(AppConstants.keyHomeSectionsVisible);
    if (saved != null && saved.isNotEmpty) {
      stored = saved;
      fromDefault = false;
    } else {
      // ترحيل: استخدم الترتيب القديم (كانت كل الأقسام ظاهرة)
      final legacy =
          prefs.getStringList(AppConstants.keyHomeSectionsOrder) ?? [];
      stored = legacy.isNotEmpty ? legacy : defaults;
      fromDefault = true;
    }

    // ترحيل v1.0.40: الأذكار الإضافية (الصباح/المساء/قبل النوم/السفر/الصلاة)
    // أُضيفت سابقًا افتراضيًا في الصفحة الرئيسية — نزيلها من الظاهرة لتصبح
    // متاحة فقط من وضع «تعديل القائمة»، مع احترام اختيار المستخدم اللاحق.
    if (!(prefs.getBool(AppConstants.keyHomeSectionsV2) ?? false)) {
      final extras = {
        for (final s in extraAdhkarHomeSections) s.id: true,
      };
      if (stored.any(extras.containsKey)) {
        stored = stored.where((id) => !extras.containsKey(id)).toList();
        await prefs.setStringList(AppConstants.keyHomeSectionsVisible, stored);
      }
      await prefs.setBool(AppConstants.keyHomeSectionsV2, true);
    }

    // ترحيل v1.0.44: إضافة بطاقة «الأربعون النووية» إلى القائمة الظاهرة مرة واحدة
    if (!(prefs.getBool(AppConstants.keyHomeSectionsV3) ?? false)) {
      if (!stored.contains('arbaeen')) {
        stored = [...stored, 'arbaeen'];
        await prefs.setStringList(AppConstants.keyHomeSectionsVisible, stored);
      }
      await prefs.setBool(AppConstants.keyHomeSectionsV3, true);
    }

    final visible = <HomeSection>[];
    for (final id in stored) {
      final s = byId[id];
      if (s != null && visible.every((x) => x.id != id)) visible.add(s);
    }
    // عند الترحيل فقط: الأقسام الجديدة التي لم تُذكر تظهر افتراضياً في النهاية.
    // أما في الحفظ اللاحق فالغائب يعني أنه مخفي بقصد المستخدم.
    if (fromDefault) {
      for (final s in homeSections) {
        if (visible.every((x) => x.id != s.id)) visible.add(s);
      }
    }

    if (mounted) {
      setState(() {
        _sections = visible;
        // المخفية = جميع الأقسام التي ليست ظاهرة (الأصلية + الإضافية)
        _hiddenSections = allSections
            .where((s) => visible.every((x) => x.id != s.id))
            .toList();
      });
      await _saveSections();
    }
  }

  Future<void> _saveSections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        AppConstants.keyHomeSectionsVisible, _sections.map((s) => s.id).toList());
  }

  /// بناء أقسام ديناميكية لفئات «أذكار أخرى» (حصن/وابل) المختارة للصفحة الرئيسية
  Future<List<HomeSection>> _loadDhikrHomeSections() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList(AppConstants.keyHomeExtraDhikr) ?? [];
    if (keys.isEmpty) return const [];
    final catMap = await DataService.instance.loadHisnWabilCategoriesByKey();
    return [
      for (final uk in keys)
        if (catMap[uk] != null)
          HomeSection(
            id: 'adhkar_extra::$uk',
            title: catMap[uk]!.title,
            icon: Icons.auto_stories,
            color: const Color(0xFF2E7D5B),
          ),
    ];
  }

  void _toggleEditMode() => setState(() => _editMode = !_editMode);

  /// إخفاء اختصار من الصفحة الرئيسية (يُضاف إلى قائمة المخفية — لا يُحذف)
  void _removeSection(String id) {
    final i = _sections.indexWhere((x) => x.id == id);
    if (i < 0) return;
    final sec = _sections[i];
    setState(() {
      _sections.removeAt(i);
      _hiddenSections.add(sec);
    });
    _saveSections();
    _syncDynamicSection(id, removed: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('أُخفي الاختصار — يمكنك إعادته من زر التعديل'),
          duration: Duration(seconds: 2)),
    );
  }

  /// إظهار اختصار مخفي مرة أخرى في نهاية القائمة
  void _addSection(String id) {
    final i = _hiddenSections.indexWhere((x) => x.id == id);
    if (i < 0) return;
    final sec = _hiddenSections[i];
    setState(() {
      _hiddenSections.removeAt(i);
      _sections.add(sec);
    });
    _saveSections();
    _syncDynamicSection(id, removed: false);
  }

  /// مزامنة الأقسام الديناميكية (فئات «أذكار أخرى») مع مفاتيح التخزين
  Future<void> _syncDynamicSection(String id, {required bool removed}) async {
    if (!id.startsWith('adhkar_extra::')) return;
    final uk = id.substring('adhkar_extra::'.length);
    final prefs = await SharedPreferences.getInstance();
    final keys =
        (prefs.getStringList(AppConstants.keyHomeExtraDhikr) ?? []).toList();
    if (removed) {
      keys.removeWhere((k) => k == uk);
    } else if (!keys.contains(uk)) {
      keys.add(uk);
    }
    await prefs.setStringList(AppConstants.keyHomeExtraDhikr, keys);
  }

  /// فتح قسم مثبّت من الصفحة الرئيسية
  void _openPinned(String key) {
    final titles = {
      'morning': 'أذكار الصباح',
      'evening': 'أذكار المساء',
      'before_sleep': 'أذكار قبل النوم',
      'travel': 'أذكار السفر',
      'prayer': 'أذكار الصلاة',
    };
    final title = titles[key] ?? key;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdhkarListScreen(categoryKey: key, title: title),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _open(BuildContext context, String id) {
    if (id.startsWith('adhkar_extra::')) {
      _openAdhkarExtra(context, id);
      return;
    }
    Widget? screen;
    switch (id) {
      case 'adhkar':
        screen = const AdhkarCategoriesScreen();
        break;
      case 'adhkar_morning':
        screen = const AdhkarListScreen(categoryKey: 'morning', title: 'أذكار الصباح');
        break;
      case 'adhkar_evening':
        screen = const AdhkarListScreen(categoryKey: 'evening', title: 'أذكار المساء');
        break;
      case 'adhkar_before_sleep':
        screen = const AdhkarListScreen(categoryKey: 'before_sleep', title: 'أذكار قبل النوم');
        break;
      case 'adhkar_travel':
        screen = const AdhkarListScreen(categoryKey: 'travel', title: 'أذكار السفر');
        break;
      case 'adhkar_prayer':
        screen = const AdhkarListScreen(categoryKey: 'prayer', title: 'أذكار الصلاة');
        break;
      case 'adhkar_sub':
        screen = const AdhkarSubCategoriesScreen();
        break;
      case 'arbaeen':
        _openArbaeen(context);
        return;
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
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!))
          .then((_) {
        // عند العودة: أعد تحميل الأقسام المثبّتة (إذ قد تتغيّر في شاشة الأذكار)
        _loadPinned();
      });
    }
  }

  Future<void> _openTelegram() async {
    final config = await DataService.instance.loadConfig();
    final uri = Uri.parse(config['telegramUrl'] ?? AppConstants.telegramUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// فتح فئة «أذكار أخرى» مضافة كقسم في الصفحة الرئيسية
  Future<void> _openAdhkarExtra(BuildContext context, String id) async {
    final uk = id.substring('adhkar_extra::'.length);
    final catMap = await DataService.instance.loadHisnWabilCategoriesByKey();
    final cat = catMap[uk];
    if (cat == null) return;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdhkarListScreen(
            categoryKey: cat.key, title: cat.title, category: cat),
      ),
    );
  }

  /// فتح كتاب الأربعين النووية المضمّن في التطبيق
  Future<void> _openArbaeen(BuildContext context) async {
    final books = await DataService.instance.loadBooksIndex();
    if (!context.mounted) return;
    Book? arbaeen;
    for (final b in books) {
      if (b.id == 'arbaeen') {
        arbaeen = b;
        break;
      }
    }
    if (arbaeen == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الكتاب غير متوفر حالياً')),
        );
      }
      return;
    }
    // بعد التأكد من عدم العدمية، نمرر نسخة غير قابلة للعدمية صراحةً
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookChaptersScreen(book: arbaeen!)),
    );
  }

  /// فتح شاشة انتقاء فئات «أذكار أخرى» لإضافتها للصفحة الرئيسية
  Future<void> _openMoreAdhkar(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdhkarSubCategoriesScreen(pickHome: true),
      ),
    );
    await _loadSections();
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
              title: const Text(''),
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
                   padding: const EdgeInsets.symmetric(horizontal: 28),
child: Center(
                       child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                            alignment: Alignment.center,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          ),
                           child: Text(
                             _displayedText(),
                             key: ValueKey(_textKey()),
                             textAlign: TextAlign.center,
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
          SliverToBoxAdapter(child: _HijriDateCard(dateStr: _hijriDateStr())),
          if (_showDailyReminders)
            const SliverToBoxAdapter(child: DailyRemindersCard()),
          if (_pinnedAdhkar.isNotEmpty)
            SliverToBoxAdapter(
              child: _PinnedBar(
                pinnedKeys: _pinnedAdhkar,
                onOpen: _openPinned,
              ),
            ),
          if (_editMode)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  'اضغط x على أي اختصار لإخفائه، وأعده الظهور من «اختصارات مخفية» في الأسفل',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
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
                        final section = _sections[index];
                        return CardItem(
                          section: section,
                          onTap: () {
                            if (!_editMode) _open(context, section.id);
                          },
                          onRemove:
                              _editMode ? () => _removeSection(section.id) : null,
                        );
                      },
                      childCount: _sections.length,
                    ),
                ),
          ),
          if (_editMode)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ActionChip(
                        avatar: const Icon(Icons.search, size: 18),
                        label: const Text('المزيد من الأذكار…'),
                        onPressed: () => _openMoreAdhkar(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_hiddenSections.isNotEmpty) ...[
                      Text(
                        'اختصارات مخفية — اضغط لإعادتها',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _hiddenSections.map((s) {
                          return ActionChip(
                            avatar: Icon(s.icon, size: 18, color: s.color),
                            label: Text(s.title),
                            onPressed: () => _addSection(s.id),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _toggleEditMode,
                  icon: Icon(_editMode ? Icons.check : Icons.edit),
                  label: Text(_editMode ? 'إنهاء التعديل' : 'تعديل القائمة'),
                ),
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

/// شريط الأقسام المثبّتة في الصفحة الرئيسية
class _PinnedBar extends StatelessWidget {
  final List<String> pinnedKeys;
  final void Function(String key) onOpen;
  const _PinnedBar({required this.pinnedKeys, required this.onOpen});

  static const _titles = {
    'morning': 'أذكار الصباح',
    'evening': 'أذكار المساء',
    'before_sleep': 'أذكار قبل النوم',
    'travel': 'أذكار السفر',
    'prayer': 'أذكار الصلاة',
  };

  static const _icons = {
    'morning': Icons.wb_sunny,
    'evening': Icons.nightlight_round,
    'before_sleep': Icons.bedtime,
    'travel': Icons.flight,
    'prayer': Icons.mosque,
  };

  @override
  Widget build(BuildContext context) {
    final valid = pinnedKeys.where(_titles.containsKey).toList();
    if (valid.isEmpty) return const SizedBox.shrink();
    return Container(
      color: AppTheme.primaryGreen.withOpacity(0.06),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'أذكاري المثبّتة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: valid.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final key = valid[index];
                return ActionChip(
                  avatar: Icon(_icons[key], size: 18, color: AppTheme.primaryGreen),
                  label: Text(_titles[key]!),
                  onPressed: () => onOpen(key),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة التاريخ الهجري المعروضة أسفل الترويسة
class _HijriDateCard extends StatelessWidget {
  final String dateStr;
  const _HijriDateCard({required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 10),
          Text(
            dateStr,
            style: const TextStyle(
              fontFamily: AppTheme.quranFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// قسم التذكيرات اليومية موجود الآن في widgets/daily_reminders_card.dart
/// ويُعرض في الصفحة الرئيسية في الزيارة الأولى فقط.

