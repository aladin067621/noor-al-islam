import 'package:flutter/material.dart';

/// ثوابت التطبيق العامة
class AppConstants {
  static const String appName = 'العروة الوثقى';
  static const String appTagline = 'القرآن والسنة وفهم السلف الصالح';
  static const String appVersion = '1.0.0';

  // مسارات الأصول (assets)
  static const String configPath = 'assets/config/app_config.json';
  static const String referencesPath = 'assets/references.md';
  static const String hisnAdhkarPath = 'assets/adhkar/hisn_al_muslim.json';
  static const String wabilAdhkarPath = 'assets/adhkar/wabil_al_sayyib.json';

  static const Map<String, String> adhkarFiles = {
    'morning': 'assets/adhkar/morning.json',
    'evening': 'assets/adhkar/evening.json',
    'before_sleep': 'assets/adhkar/before_sleep.json',
    'travel': 'assets/adhkar/travel.json',
    'prayer': 'assets/adhkar/prayer_adhkar.json',
    'other': 'assets/adhkar/other_adhkar.json',
  };

  static const String prayerStepsFile = 'assets/prayer/prayer_steps.json';
  static const String tawheedFile = 'assets/tawheed/tawheed.json';
  static const String pillarsFile = 'assets/pillars/pillars.json';
  static const String booksIndexFile = 'assets/books/index.json';
  static const String tafsirFile = 'assets/tafsir/tafsir.json';

  // مسارات أصول القرآن (نص + ألوان تجويد — من Quran-Tajweed-Engine دون تعديل)
  static const String quranSurahsPath = 'assets/quran/surahs';
  static const String quranTajweedPath = 'assets/quran/tajweed';
  static const String quranRulesPath = 'assets/quran/tajweed-rules.json';
  static const String quranJuzPath = 'assets/quran/juz.json';
  static const String quranUthmaniFont = 'QuranUthmani';
  static const String quranIndopakFont = 'QuranIndopak';

  // الصوت — alquran.cloud (Islamic Network) — بث + تخزين مؤقت للآيات
  static const String quranAudioBase = 'https://cdn.islamic.network/quran/audio/128';
  // نطاق احتياطي تابع لـ alquran.cloud نفسها يُجرَّب عند فشل الأساسي
  static const String quranAudioBaseSecondary = 'https://cdn.islamicnetwork.com/quran/audio/128';
  static const String defaultReciter = 'ar.husary'; // محمود خليل الحصري (مرتّل)

  // مفاتيح shared_preferences
  static const String keyDarkMode = 'dark_mode';
  static const String keyFontSize = 'font_size';
  static const String keyMorningReminder = 'morning_reminder_enabled';
  static const String keyMorningTime = 'morning_reminder_time';
  static const String keyEveningReminder = 'evening_reminder_enabled';
  static const String keyEveningTime = 'evening_reminder_time';
  static const String keyPopupEnabled = 'popup_enabled';
  static const String keyPopupInterval = 'popup_interval_minutes';
  static const String keyPopupAdhkar = 'popup_adhkar_list';

  // مفاتيح الإذن الأول والتذكيرات اليومية
  static const String keyFirstLaunchDone = 'first_launch_done';
  static const String keySunnahReminders = 'sunnah_reminders_enabled';
  static const String keyDailyRemindersSeen = 'daily_reminders_seen';

  // مفاتيح تخصيص الأذكار (shared_preferences)
  static const String keyAdhkarOrder = 'adhkar_order';
  static const String keySubAdhkarOrder = 'adhkar_sub_order';
  static const String keyPinnedAdhkar = 'adhkar_pinned_list';

  // ترتيب أقسام الصفحة الرئيسية
  static const String keyHomeSectionsOrder = 'home_sections_order';
  // الأقسام الظاهرة في الصفحة الرئيسية (مع الترتيب) — الأقسام التي لا تظهر محفوظة ضمنها
  static const String keyHomeSectionsVisible = 'home_sections_visible';
  // علم ترحيل: فُصلت بطاقات الأذكار الإضافية عن القائمة الافتراضية (ظهرت سابقًا افتراضيًا)
  static const String keyHomeSectionsV2 = 'home_sections_v2';

  // مفاتيح قسم حفظ القرآن (محلية فقط — لا يوجد تسجيل/إعلانات/ميكروفون)
  static const String keyHifzStatus = 'hifz_status_v1';
  static const String keyHifzSessions = 'hifz_sessions_v1';
  static const String keyHifzSettings = 'hifz_settings_v1';
  // بيانات المراجعة المتباعدة لكل آية (المرحلة، تاريخ الاستحقاق، تاريخ الحفظ)
  static const String keyHifzMeta = 'hifz_meta_v1';

  // مفاتيح الموقع المحفوظ (مدينة يدوية أو إحداثيات GPS)
  static const String keyLocationLat = 'location_lat';
  static const String keyLocationLon = 'location_lon';
  static const String keyLocationCity = 'location_city';
  static const String keyLocationSource = 'location_source'; // gps | manual

  // القيم الافتراضية
  static const double defaultFontSize = 18.0;
  static const double minFontSize = 14.0;
  static const double maxFontSize = 28.0;
  static const String defaultMorningTime = '06:00';
  static const String defaultEveningTime = '17:00';
  static const int defaultPopupInterval = 60;

  // قناة تيليجرام (افتراضي، يُقرأ من app_config.json)
  static const String telegramUrl = 'https://t.me/muslimindz';
}

/// أقسام التطبيق المعروضة في الصفحة الرئيسية
class HomeSection {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  const HomeSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

/// الأقسام الأصلية في الصفحة الرئيسية (تظهر افتراضياً)
const List<HomeSection> homeSections = [
  HomeSection(id: 'adhkar', title: 'الأذكار', icon: Icons.spa, color: Color(0xFF2E7D5B)),
  HomeSection(id: 'asma', title: 'أسماء الله الحسنى', icon: Icons.auto_awesome, color: Color(0xFFB8860B)),
  HomeSection(id: 'prayer', title: 'الصلاة', icon: Icons.mosque, color: Color(0xFF1B6B5A)),
  HomeSection(id: 'prayer_times', title: 'مواقيت الصلاة', icon: Icons.access_time, color: Color(0xFF2E7D5B)),
  HomeSection(id: 'qibla', title: 'اتجاه القبلة', icon: Icons.explore, color: Color(0xFF1B6B5A)),
  HomeSection(id: 'hijri', title: 'التقويم الهجري', icon: Icons.calendar_month, color: Color(0xFF8B6914)),
  HomeSection(id: 'tawheed', title: 'التوحيد', icon: Icons.brightness_7, color: Color(0xFFB8860B)),
  HomeSection(id: 'pillars', title: 'أركان الإسلام', icon: Icons.auto_stories, color: Color(0xFF8B6914)),
  HomeSection(id: 'tafsir', title: 'تفسير القرآن', icon: Icons.menu_book, color: Color(0xFF2E7D5B)),
  HomeSection(id: 'library', title: 'المكتبة', icon: Icons.library_books, color: Color(0xFF1B6B5A)),
  HomeSection(id: 'memorization', title: 'حفظ القرآن', icon: Icons.psychology, color: Color(0xFFB8860B)),
  HomeSection(id: 'favorites', title: 'المفضلة', icon: Icons.favorite, color: Color(0xFFC0392B)),
  HomeSection(id: 'notes', title: 'الملاحظات', icon: Icons.edit_note, color: Color(0xFF8B6914)),
  HomeSection(id: 'search', title: 'البحث', icon: Icons.search, color: Color(0xFF2E7D5B)),
];

/// أقسام إضافية للتعديل — تظهر فقط في وضع تعديل القائمة كخيارات قابلة للإضافة
const List<HomeSection> extraAdhkarHomeSections = [
  HomeSection(id: 'adhkar_morning', title: 'أذكار الصباح', icon: Icons.wb_sunny, color: Color(0xFF2E7D5B)),
  HomeSection(id: 'adhkar_evening', title: 'أذكار المساء', icon: Icons.nightlight_round, color: Color(0xFF2E7D5B)),
  HomeSection(id: 'adhkar_before_sleep', title: 'أذكار قبل النوم', icon: Icons.bedtime, color: Color(0xFF2E7D5B)),
  HomeSection(id: 'adhkar_travel', title: 'أذكار السفر', icon: Icons.flight, color: Color(0xFF2E7D5B)),
  HomeSection(id: 'adhkar_prayer', title: 'أذكار الصلاة', icon: Icons.mosque, color: Color(0xFF2E7D5B)),
  HomeSection(id: 'adhkar_sub', title: 'أذكار أخرى', icon: Icons.list, color: Color(0xFF2E7D5B)),
];
