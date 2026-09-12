import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/quran_models.dart';
import '../../services/data_service.dart';
import '../../services/quran_audio_service.dart';
import '../../services/quran_data_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/tajweed_text.dart';
import '../quran_tafsir/tafsir_surah_screen.dart';
import 'tajweed_rules_screen.dart';

/// قارئ المصحف المنفصل — عرض يشبه المصحف الحقيقي:
/// — صفحات متتابعة (حسب حقل page في بيانات الآيات) بنص متصل.
/// — علامة آية نهاية كل آية «﴿١﴾» داخليًا.
/// — وضع قراءة أسود/أبيض قابل للتبديل.
/// — ضغط أي آية يفتح نافذة إجراءات (تفسير/علامة/تلاوة).
class MushafReaderScreen extends StatefulWidget {
  final int surahId;
  final int initialAyah;

  const MushafReaderScreen({
    super.key,
    required this.surahId,
    this.initialAyah = 1,
  });

  @override
  State<MushafReaderScreen> createState() => _MushafReaderScreenState();
}

class _MushafReaderScreenState extends State<MushafReaderScreen> {
  QuranSurah? _surah;
  Map<int, List<TajweedSpan>>? _tajweed;
  Map<String, String>? _ruleColors;
  String _basmalah = '';
  bool _error = false;
  int? _bookmarkAyah;
  bool _darkMode = false;

  // صفحات السورة: كل صفحة قائمة آياتها بالترتيب (حسب حقل page)
  late List<List<QuranAyah>> _pages = [];
  final ScrollController _scroll = ScrollController();

  // تقدير ارتفاع الصفحة للانتقال إلى علامة القراءة (التنقل بسرعة إلى الصفحة)
  double _pageExtent = 0;

  static const String _prefDark = 'mushaf_dark_mode';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = QuranDataService.instance;
      final surah = await data.loadSurah(widget.surahId);
      final tajweed = await data.loadTajweed(widget.surahId);
      final colors = await data.loadRuleColors();
      var basmalah = '';
      if (surah.id != 9) {
        final fatiha = await data.loadSurah(1);
        basmalah = fatiha.ayahAt(1).textArabic;
      }
      final prefs = await SharedPreferences.getInstance();
      final dark = prefs.getBool(_prefDark) ?? false;
      final raw = prefs.getString(AppConstants.keyMushafBookmark);
      int? bmAyah;
      if (raw != null) {
        final p = raw.split(':');
        if (p.length == 2 && int.tryParse(p[0]) == widget.surahId) {
          bmAyah = int.tryParse(p[1]);
        }
      }
      // تجميع الآيات في صفحات
      final pages = <List<QuranAyah>>[];
      var current = <QuranAyah>[];
      var lastPage = -1;
      for (final ayah in surah.ayahs) {
        if (ayah.page != lastPage && current.isNotEmpty) {
          pages.add(current);
          current = <QuranAyah>[];
        }
        current.add(ayah);
        lastPage = ayah.page;
      }
      if (current.isNotEmpty) pages.add(current);

      if (!mounted) return;
      setState(() {
        _surah = surah;
        _tajweed = tajweed;
        _ruleColors = colors;
        _basmalah = basmalah;
        _bookmarkAyah = bmAyah;
        _darkMode = dark;
        _pages = pages;
      });
      final target = widget.initialAyah > 1
          ? widget.initialAyah
          : (bmAyah != null && bmAyah > 1 ? bmAyah : 1);
      if (target > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToAyah(target);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _scrollToAyah(int ayah) {
    if (_pageExtent <= 0) _estimatePageExtent();
    final pageIndex = _pageIndexOfAyah(ayah);
    if (pageIndex < 0) return;
    // بسمله أول قائمة إذا وُجدت ⇒ إزاحة صفحة إضافية
    final itemIndex = pageIndex + (_basmalah.isEmpty ? 0 : 1);
    final dy = (itemIndex * _pageExtent) - 8;
    if (dy > 0) {
      _scroll.animateTo(dy,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  int _pageIndexOfAyah(int ayah) {
    for (var i = 0; i < _pages.length; i++) {
      final p = _pages[i];
      if (p.any((a) => a.number == ayah)) return i;
    }
    return -1;
  }

  /// تقدير ارتفاع الصفحة الواحدة (عدد الحروف ÷ حروف السطر الواحد × ارتفاع السطر)
  void _estimatePageExtent() {
    if (!_surahLoaded) return;
    final lineHeight = 1.9 * 27.0; // ارتفاع سطر بمقياس خط الصفحة
    const charsPerLine = 26.0;
    var totalEst = 0.0;
    for (final page in _pages) {
      var letters = 0;
      for (final a in page) letters += a.textArabic.runes.length;
      totalEst += ((letters / charsPerLine).ceil()) * lineHeight;
    }
    totalEst += (_pages.length + ( _basmalah.isEmpty ? 0 : 1)) * 90; // هوامش/رقم
    _pageExtent = totalEst / (_pages.length + (_basmalah.isEmpty ? 0 : 1));
  }

  bool get _surahLoaded => _surah != null;

  Future<void> _setBookmark(int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.keyMushafBookmark, '${widget.surahId}:$ayah');
    if (!mounted) return;
    setState(() => _bookmarkAyah = ayah);
    _snack('وُضعت العلامة عند آية ${toArabicDigits(ayah)}');
  }

  Future<void> _clearBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyMushafBookmark);
    if (!mounted) return;
    setState(() => _bookmarkAyah = null);
    _snack('حُذفت العلامة');
  }

  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final next = !_darkMode;
    setState(() => _darkMode = next);
    await prefs.setBool(_prefDark, next);
  }

  void _playAll() {
    final s = _surah;
    if (s == null) return;
    QuranAudioService.instance.init().then((_) {
      QuranAudioService.instance
          .playRange(QuranPos(s.id, 1), QuranPos(s.id, s.numberOfAyahs));
    });
  }

  Future<void> _openTafsir(int ayahNum) async {
    final surahs = await DataService.instance.loadTafsirSurahs();
    if (!mounted) return;
    Map<String, dynamic>? target;
    for (final e in surahs) {
      final m = e as Map<String, dynamic>;
      if (m['id'] == widget.surahId) {
        target = m;
        break;
      }
    }
    if (target == null) {
      _snack('التفسير غير متوفر لهذه السورة');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TafsirSurahScreen(surah: target!, initialAyah: ayahNum),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_surah == null ? '…' : 'سورة ${_surah!.nameArabic}'),
        actions: [
          IconButton(
            tooltip: 'استماع للسورة كاملة',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: _surah == null ? null : _playAll,
          ),
          IconButton(
            tooltip: 'أحكام التجويد',
            icon: const Icon(Icons.menu_book),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TajweedRulesScreen()),
              );
            },
          ),
          IconButton(
            tooltip: _darkMode ? 'وضع النهار (أبيض)' : 'وضع الليل (أسود)',
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleDarkMode,
          ),
          if (_bookmarkAyah != null)
            PopupMenuButton<String>(
              tooltip: 'علامة القراءة',
              icon: const Icon(Icons.bookmark, color: AppTheme.gold),
              onSelected: (v) {
                if (v == 'jump' && _bookmarkAyah != null) {
                  _scrollToAyah(_bookmarkAyah!);
                } else if (v == 'clear') {
                  _clearBookmark();
                }
              },
              itemBuilder: (_) => [
                if (_bookmarkAyah != null)
                  PopupMenuItem(
                    value: 'jump',
                    child: Text('الانتقال إلى آية ${toArabicDigits(_bookmarkAyah!)}'),
                  ),
                PopupMenuItem(
                  value: 'clear',
                  child: Text('حذف علامة هذه السورة',
                      style: TextStyle(color: AppTheme.dangerRed)),
                ),
              ],
            )
          else
            const IconButton(
              tooltip: 'لا توجد علامة',
              icon: Icon(Icons.bookmark_border, color: Colors.grey),
              onPressed: null,
            ),
        ],
      ),
      body: _error
          ? const Center(child: Text('تعذّر تحميل السورة'))
          : (_surah == null
              ? const Center(child: CircularProgressIndicator())
              : _buildMushaf()),
    );
  }

  Widget _buildMushaf() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_pageExtent <= 0) _estimatePageExtent();
        final bg = _darkMode
            ? const Color(0xFF0E0B07)
            : const Color(0xFFF8F5EE);
        final paper = _darkMode
            ? const Color(0xFF171310)
            : const Color(0xFFFFFDF7);
        final textColor = _darkMode ? Colors.white : const Color(0xFF1A1A1A);
        return Container(
          color: bg,
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            itemCount: _pages.length + (_basmalah.isEmpty ? 0 : 1),
            itemBuilder: (context, index) {
              if (_basmalah.isNotEmpty && index == 0) {
                return _mushafPage(
                  paper: paper,
                  textColor: textColor,
                  children: [_basmalahLine()],
                  pageNumber: null,
                );
              }
              final pageIndex = index - (_basmalah.isEmpty ? 0 : 1);
              final page = _pages[pageIndex];
              return _mushafPage(
                paper: paper,
                textColor: textColor,
                children: [
                  for (final ayah in page) _ayahLine(ayah, textColor),
                ],
                pageNumber: page.first.page,
              );
            },
          ),
        );
      },
    );
  }

  Widget _mushafPage({
    required Color paper,
    required Color textColor,
    required List<Widget> children,
    required int? pageNumber,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_darkMode ? 0.35 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in children) c,
          if (pageNumber != null)
            Align(alignment: Alignment.center, child: _pageNumberBadge(pageNumber, textColor)),
        ],
      ),
    );
  }

  Widget _basmalahLine() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: TajweedText(
          text: _basmalah,
          spans: const [],
          ruleColors: _ruleColors!,
          tajweedOn: false,
          fontSize: 24,
          fontFamily: AppConstants.quranUthmaniFont,
        ),
      ),
    );
  }

  /// آية بنص متصل وعلامة نهاية «﴿رقم﴾» داخليًا — قابلة للمس لفتح الإجراءات
  Widget _ayahLine(QuranAyah ayah, Color textColor) {
    final ayahText = ayah.textArabic;
    // إلحاق علامة نهاية الآية داخل نفس السطر (بعد النص، خارج نطاق التلوين)
    final inline = '  ﴿${toArabicDigits(ayah.number)}﴾';
    final isBookmark = _bookmarkAyah == ayah.number;

    Widget line = TajweedText(
      text: ayahText + inline,
      spans: _tajweed![ayah.number] ?? const <TajweedSpan>[],
      ruleColors: _ruleColors!,
      tajweedOn: true,
      fontSize: 27,
      fontFamily: AppConstants.quranUthmaniFont,
      color: textColor,
    );

    if (isBookmark) {
      line = Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.gold.withOpacity(_darkMode ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: line,
      );
    }

    return Semantics(
      button: true,
      label: 'آية ${toArabicDigits(ayah.number)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _showAyahActions(ayah.number, ayahText),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: line,
        ),
      ),
    );
  }

  Widget _pageNumberBadge(int page, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: textColor.withOpacity(0.25), width: 0.8),
              bottom: BorderSide(
                  color: textColor.withOpacity(0.25), width: 0.8),
            ),
          ),
          child: Text(
            toArabicDigits(page),
            style: TextStyle(
              fontSize: 13,
              color: textColor.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAyahActions(int ayahNum, String ayahText) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _darkMode ? const Color(0xFF1E1915) : null,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TajweedText(
                  text: ayahText,
                  spans: _tajweed![ayahNum] ?? const <TajweedSpan>[],
                  ruleColors: _ruleColors!,
                  tajweedOn: false,
                  fontSize: 20,
                  fontFamily: AppConstants.quranUthmaniFont,
                  color: _darkMode
                      ? Colors.white
                      : Theme.of(sheetContext).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: AppTheme.gold),
                title: const Text('التفسير لهذه الآية'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openTafsir(ayahNum);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined, color: AppTheme.primaryGreen),
                title: Text(_bookmarkAyah == ayahNum
                    ? 'حذف العلامة من هذه الآية'
                    : 'وضع علامة هنا (للمتابعة لاحقًا)'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (_bookmarkAyah == ayahNum) {
                    _clearBookmark();
                  } else {
                    _setBookmark(ayahNum);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline, color: AppTheme.successGreen),
                title: const Text('تشغيل التلاوة'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  QuranAudioService.instance.init().then((_) {
                    QuranAudioService.instance
                        .playAyah(QuranPos(widget.surahId, ayahNum));
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}