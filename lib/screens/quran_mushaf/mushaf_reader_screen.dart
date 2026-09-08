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

/// قارئ المصحف المنفصل — نص كامل مع ألوان التجويد، علامة قراءة (استئناف)،
/// ورابط لكل آية إلى تفسيرها.
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
  final ScrollController _scroll = ScrollController();

  static const double _ayahExtent = 84.0;

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
      final raw = prefs.getString(AppConstants.keyMushafBookmark);
      int? bmAyah;
      if (raw != null) {
        final p = raw.split(':');
        if (p.length == 2 && int.tryParse(p[0]) == widget.surahId) {
          bmAyah = int.tryParse(p[1]);
        }
      }
      if (!mounted) return;
      setState(() {
        _surah = surah;
        _tajweed = tajweed;
        _ruleColors = colors;
        _basmalah = basmalah;
        _bookmarkAyah = bmAyah;
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
    if (ayah < 1) return;
    final dy = _ayahExtent * (ayah - 1);
    if (dy > 0) _scroll.animateTo(dy,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

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
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _surah!.numberOfAyahs + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      if (_basmalah.isEmpty) return const SizedBox(height: 4);
                      return _basmalahCard();
                    }
                    return _ayahCard(index);
                  },
                )),
    );
  }

  Widget _basmalahCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.gold.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
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

  Widget _ayahCard(int ayahNum) {
    final surah = _surah!;
    final ayah = surah.ayahAt(ayahNum);
    final spans = _tajweed![ayahNum] ?? const <TajweedSpan>[];
    final isBookmark = _bookmarkAyah == ayahNum;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isBookmark ? AppTheme.gold.withOpacity(0.10) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAyahActions(ayahNum, ayah.textArabic),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TajweedText(
                  text: ayah.textArabic,
                  spans: spans,
                  ruleColors: _ruleColors!,
                  tajweedOn: true,
                  fontSize: 26,
                  fontFamily: AppConstants.quranUthmaniFont,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isBookmark
                          ? AppTheme.gold
                          : AppTheme.primaryGreen.withOpacity(0.5)),
                ),
                child: Text(
                  '﴿${toArabicDigits(ayahNum)}﴾',
                  style: TextStyle(
                      color: isBookmark ? AppTheme.gold : AppTheme.primaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAyahActions(int ayahNum, String ayahText) async {
    await showModalBottomSheet<void>(
      context: context,
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