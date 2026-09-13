import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
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

/// قارئ المصحف المنفصل — عرض يشبه المصحف المطبوع:
/// — صفحات متتابعة (حسب حقل page في بيانات الآيات) بإطار مزخرف ورقم صفحة وسطي.
/// — ترويسة سورة (اسمها وصفتها وعدد آياتها) والبسملة في أول صفحة.
/// — نص متصل مضبوط الجهتين داخل الصفحة مع «﴿رقم﴾» نهاية كل آية.
/// — وضع قراءة أسود/أبيض قابل للتبديل.
/// — ضغط أي آية يفتح نافذة إجراءات (تفسير/علامة/تلاوة).
/// — شريط صوتي دائم (إيقاف/متابعة/إيقاف) أثناء التلاوة.
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
  static const double _kFontSize = 27.0;
  static const String _prefDark = 'mushaf_dark_mode';

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

  // تقدير ارتفاع الصفحة للانتقال إلى علامة القراءة (تنقل سريع إلى الصفحة)
  double _pageExtent = 0;

  // معرّفات النقر لكل آية (تُنشأ مرة واحدة وتُتلف عند مغادرة الشاشة)
  final Map<int, TapGestureRecognizer> _taps = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final t in _taps.values) {
      t.dispose();
    }
    _taps.clear();
    // إيقاف تلاوة السورة عند مغادرة الشاشة (لا تستمر في الخلفية)
    if (QuranAudioService.instance.continuous) {
      QuranAudioService.instance.stop();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = QuranDataService.instance;
      final surah = await data.loadSurah(widget.surahId);
      final tajweed = await data.loadTajweed(widget.surahId);
      final colors = await data.loadRuleColors();
      var basmalah = '';
      if (surah.id != 9 && surah.id != 1) {
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
      // تجميع الآيات في صفحات المصحف (كل صفحة قائمة آياتها)
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

  // ==================== الصوت ====================

  void _playAll() {
    final s = _surah;
    if (s == null) return;
    QuranAudioService.instance.init().then((_) {
      QuranAudioService.instance.playSurah(s.id, s.numberOfAyahs);
    });
  }

  void _playAyah(int ayahNum) {
    QuranAudioService.instance.init().then((_) {
      QuranAudioService.instance.playAyah(QuranPos(widget.surahId, ayahNum),
          continuous: true);
    });
  }

  /// شريط التحكم بالتلاوة — يظهر أثناء التحميل/التشغيل ويُخفى عند التوقف.
  Widget _playerBar() {
    final svc = QuranAudioService.instance;
    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        if (!svc.playing && !svc.downloading) return const SizedBox.shrink();
        final cur = svc.current;
        final label = cur == null
            ? 'التلاوة'
            : 'سورة ${_stripHarakat(_surah?.nameArabic ?? '')} — آية ${toArabicDigits(cur.ayah)}';
        final bar = Material(
          elevation: 10,
          color: _darkMode ? const Color(0xFF1E1915) : const Color(0xFFFFFDF7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                if (svc.downloading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                else
                  const Icon(Icons.volume_up, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _darkMode ? Colors.white : const Color(0xFF1A1A1A),
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: svc.playing ? 'إيقاف مؤقت' : 'متابعة التلاوة',
                  icon: Icon(
                    svc.playing
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: AppTheme.primaryGreen,
                  ),
                  onPressed: svc.playing
                      ? () => unawaited(svc.pause())
                      : () => unawaited(svc.resume()),
                ),
                IconButton(
                  tooltip: 'إيقاف التلاوة',
                  icon: const Icon(Icons.stop_circle_outlined,
                      color: AppTheme.dangerRed),
                  onPressed: () => unawaited(svc.stop()),
                ),
              ],
            ),
          ),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 1,
              color: _darkMode
                  ? const Color(0xFF3A3128)
                  : const Color(0xFFE4DCC8),
            ),
            bar,
          ],
        );
      },
    );
  }

  // ==================== العلامة ====================

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

  /// وضع العلامة عند أول آية من الصفحة الظاهرة حاليًا.
  void _placeBookmarkHere() {
    if (_pages.isEmpty) return;
    if (_pageExtent <= 0) _estimatePageExtent();
    var index = (_scroll.offset / (_pageExtent > 0 ? _pageExtent : 1)).floor();
    index = index.clamp(0, _pages.length - 1);
    final page = _pages[index];
    _setBookmark(page.isEmpty ? 1 : page.first.number);
  }

  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final next = !_darkMode;
    setState(() => _darkMode = next);
    await prefs.setBool(_prefDark, next);
  }

  // ==================== التنقل ====================

  void _scrollToAyah(int ayah) {
    if (_pageExtent <= 0) _estimatePageExtent();
    final pageIndex = _pageIndexOfAyah(ayah);
    if (pageIndex < 0) return;
    final dy = (pageIndex * _pageExtent) - 8;
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

  void _estimatePageExtent() {
    if (!_surahLoaded) return;
    final lineHeight = 1.9 * _kFontSize;
    const charsPerLine = 26.0;
    var totalEst = 0.0;
    for (final page in _pages) {
      var letters = 0;
      for (final a in page) letters += a.textArabic.runes.length;
      totalEst += ((letters / charsPerLine).ceil()) * lineHeight;
    }
    // هوامش وإطار ورقم صفحة وترويسة في أول صفحة
    totalEst += _pages.length * 110;
    _pageExtent = totalEst / _pages.length;
  }

  bool get _surahLoaded => _surah != null;

  TapGestureRecognizer _tapFor(int n) => _taps.putIfAbsent(
      n,
      () => TapGestureRecognizer()
        ..onTap = () {
          if (mounted) {
            _showAyahActions(n, _surah!.ayahAt(n).textArabic);
          }
        });

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

  // ==================== العرض ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_surah == null ? '…' : 'سورة ${_stripHarakat(_surah!.nameArabic)}'),
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
          PopupMenuButton<String>(
            tooltip: 'علامة القراءة',
            icon: Icon(
              _bookmarkAyah != null
                  ? Icons.bookmark
                  : Icons.bookmark_add_outlined,
              color: _bookmarkAyah != null ? AppTheme.gold : AppTheme.primaryGreen,
            ),
            onSelected: (v) {
              if (v == 'here') {
                _placeBookmarkHere();
              } else if (v == 'jump' && _bookmarkAyah != null) {
                _scrollToAyah(_bookmarkAyah!);
              } else if (v == 'clear') {
                _clearBookmark();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'here',
                child: Text(_bookmarkAyah != null
                    ? 'تغيير العلامة إلى المكان الحالي'
                    : 'وضع علامة هنا (المكان الحالي)'),
              ),
              if (_bookmarkAyah != null)
                PopupMenuItem(
                  value: 'jump',
                  child: Text(
                      'الانتقال إلى آية ${toArabicDigits(_bookmarkAyah!)}'),
                ),
              if (_bookmarkAyah != null)
                PopupMenuItem(
                  value: 'clear',
                  child: Text('حذف علامة هذه السورة',
                      style: TextStyle(color: AppTheme.dangerRed)),
                ),
            ],
          ),
        ],
      ),
      body: _error
          ? const Center(child: Text('تعذّر تحميل السورة'))
          : (_surah == null
              ? const Center(child: CircularProgressIndicator())
              : _buildMushaf()),
      bottomNavigationBar: _playerBar(),
    );
  }

  Widget _buildMushaf() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_pageExtent <= 0) _estimatePageExtent();
        final dark = _darkMode;
        final bg = dark ? const Color(0xFF0E0B07) : const Color(0xFFEDE4D2);
        final paper = dark ? const Color(0xFF131009) : const Color(0xFFFFFCF3);
        final textColor =
            dark ? const Color(0xFFF0E9DA) : const Color(0xFF241C12);
        final border = dark ? const Color(0xFF8C7B4C) : const Color(0xFFB8860B);
        return Container(
          width: double.infinity,
          color: bg,
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _mushafPage(
              page: _pages[index],
              isFirstPage: index == 0,
              paper: paper,
              textColor: textColor,
              border: border,
            ),
          ),
        );
      },
    );
  }

  Widget _mushafPage({
    required List<QuranAyah> page,
    required bool isFirstPage,
    required Color paper,
    required Color textColor,
    required Color border,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: BoxDecoration(
              color: paper,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: border, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_darkMode ? 0.4 : 0.12),
                  blurRadius: 9,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _pageNumberOrnament(page.first.page, textColor)),
                if (isFirstPage) ...[
                  const SizedBox(height: 12),
                  _surahHeader(textColor, border),
                  if (_basmalah.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _basmalahBlock(textColor),
                  ],
                ],
                const SizedBox(height: 14),
                _pageText(page, textColor),
              ],
            ),
          ),
          ..._cornerOrnaments(border, paper),
        ],
      ),
    );
  }

  /// رقم الصفحة في منتصف أعلى الصفحة (على غرار المصاحف المطبوعة)
  Widget _pageNumberOrnament(int page, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal:
              BorderSide(color: AppTheme.gold.withOpacity(0.55), width: 1),
        ),
      ),
      child: Text(
        toArabicDigits(page),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textColor.withOpacity(0.85),
        ),
      ),
    );
  }

  /// ترويسة السورة: اسم السورة في الوسط وصفتها وعدد آياتها في جانبيه
  Widget _surahHeader(Color textColor, Color border) {
    final s = _surah!;
    final label = s.type == 'medinan' ? 'مدنية' : 'مكية';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: 1.4),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _sideTag(label, textColor),
          Expanded(
            child: Center(
              child: Text(
                'سورة ${_stripHarakat(s.nameArabic)}',
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
          ),
          _sideTag('${toArabicDigits(s.numberOfAyahs)} آية', textColor),
        ],
      ),
    );
  }

  Widget _sideTag(String label, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.gold.withOpacity(0.55), width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.85)),
      ),
    );
  }

  Widget _basmalahBlock(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x33B8860B), width: 1)),
        ),
        child: Center(
          child: TajweedText(
            text: _basmalah,
            spans: const [],
            ruleColors: _ruleColors!,
            tajweedOn: false,
            fontSize: 24,
            fontFamily: AppConstants.quranUthmaniFont,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// زخارف مربطة بزوايا الإطار (على نمط إطارات المصاحف)
  List<Widget> _cornerOrnaments(Color border, Color paper) {
    final size = 9.0;
    Widget diamond() => Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: paper,
              border: Border.all(color: border, width: 1.3),
            ),
          ),
        );
    return [
      Positioned(top: 2, right: 12, child: diamond()),
      Positioned(top: 2, left: 12, child: diamond()),
      Positioned(bottom: 2, right: 12, child: diamond()),
      Positioned(bottom: 2, left: 12, child: diamond()),
    ];
  }

  /// نص الصفحة — آيات متصلة داخل سطر واحد يلتف لأسفل، مع نهاية آية «﴿رقم﴾»
  /// وكل آية قابلة للمس لفتح الإجراءات.
  Widget _pageText(List<QuranAyah> page, Color textColor) {
    final base = TextStyle(
      fontFamily: AppConstants.quranUthmaniFont,
      fontSize: _kFontSize,
      height: 1.9,
      color: textColor,
    );
    final groups = <InlineSpan>[
      for (final ayah in page) _ayahSpan(ayah),
    ];
    return Text.rich(
      TextSpan(style: base, children: groups),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      softWrap: true,
    );
  }

  InlineSpan _ayahSpan(QuranAyah ayah) {
    final colored = buildTajweedInlines(
      text: ayah.textArabic,
      spans: _tajweed![ayah.number] ?? const <TajweedSpan>[],
      ruleColors: _ruleColors!,
      tajweedOn: true,
    );
    final isBookmark = _bookmarkAyah == ayah.number;
    return TextSpan(
      recognizer: _tapFor(ayah.number),
      style: isBookmark
          ? TextStyle(
              backgroundColor:
                  AppTheme.gold.withOpacity(_darkMode ? 0.22 : 0.14),
            )
          : null,
      children: [
        if (colored != null)
          ...colored
        else
          TextSpan(text: ayah.textArabic),
        TextSpan(
          text: '  ﴿${toArabicDigits(ayah.number)}﴾',
          style: TextStyle(color: AppTheme.gold.withOpacity(0.85)),
        ),
      ],
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
                leading: const Icon(Icons.bookmark_add_outlined,
                    color: AppTheme.primaryGreen),
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
                leading: const Icon(Icons.play_circle_outline,
                    color: AppTheme.successGreen),
                title: const Text('تشغيل التلاوة'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _playAyah(ayahNum);
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

  /// إزالة التشكيل والتنوين من اسم السورة لعرضه في الترويسة
  String _stripHarakat(String s) {
    final buf = StringBuffer();
    for (final cp in s.runes) {
      final inRange = (cp >= 0x064B && cp <= 0x065F) ||
          cp == 0x0670 ||
          cp == 0x0640 ||
          (cp >= 0x06D6 && cp <= 0x06DC) ||
          (cp >= 0x06DF && cp <= 0x06E8) ||
          (cp >= 0x06EA && cp <= 0x06ED);
      if (!inRange) buf.writeCharCode(cp);
    }
    return buf.toString();
  }
}