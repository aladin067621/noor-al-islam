import 'package:flutter/material.dart';
import '../../models/quran_models.dart';
import '../../services/hifz_service.dart';
import '../../services/quran_audio_service.dart';
import '../../services/quran_data_service.dart';
import '../../utils/theme.dart';
import '../../widgets/tajweed_text.dart';
import 'hifz_test_tab.dart';
import 'hifz_widgets.dart';

/// قارئ سورة من المصحف مع ألوان التجويد وإجراءات الآية
class HifzReaderScreen extends StatefulWidget {
  final int surahId;
  final int initialAyah;

  const HifzReaderScreen({
    super.key,
    required this.surahId,
    this.initialAyah = 1,
  });

  @override
  State<HifzReaderScreen> createState() => _HifzReaderScreenState();
}

class _HifzReaderScreenState extends State<HifzReaderScreen> {
  QuranSurah? _surah;
  Map<int, List<TajweedSpan>>? _tajweed;
  Map<String, String>? _ruleColors;
  String _basmalah = '';
  bool _error = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
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
      if (!mounted) return;
      setState(() {
        _surah = surah;
        _tajweed = tajweed;
        _ruleColors = colors;
        _basmalah = basmalah;
      });
      if (widget.initialAyah > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAyah(widget.initialAyah));
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _scrollToAyah(int ayah) {
    if (ayah < 1) return;
    final dy = 84.0 * (ayah - 1);
    if (dy > 0) _scroll.animateTo(dy,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _playAll() {
    final s = _surah;
    if (s == null) return;
    QuranAudioService.instance.playRange(QuranPos(s.id, 1), QuranPos(s.id, s.numberOfAyahs));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hifz = HifzService.instance;
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
            tooltip: 'ألوان التجويد',
            icon: Icon(hifz.settings.tajweed
                ? Icons.palette_outlined
                : Icons.palette_outlined),
            onPressed: () {
              hifz.settings.tajweed = !hifz.settings.tajweed;
              hifz.saveSettings();
            },
          ),
        ],
      ),
      body: _error
          ? const Center(child: Text('تعذّر تحميل السورة'))
          : (_surah == null
              ? const Center(child: CircularProgressIndicator())
              : AnimatedBuilder(
                  animation: Listenable.merge([hifz, QuranAudioService.instance]),
                  builder: (context, _) => ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _surah!.numberOfAyahs + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        if (_basmalah.isEmpty) return const SizedBox(height: 4);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: TajweedText(
                              text: _basmalah,
                              spans: const [],
                              ruleColors: _ruleColors!,
                              tajweedOn: false,
                              fontSize: hifz.settings.mushafFontSize * 0.9,
                              fontFamily: quranFontFamily(),
                            ),
                          ),
                        );
                      }
                      return _ayahCard(context, index);
                    },
                  ),
                )),
    );
  }

  Widget _ayahCard(BuildContext context, int ayahNum) {
    final surah = _surah!;
    final ayah = surah.ayahAt(ayahNum);
    final pos = QuranPos(surah.id, ayahNum);
    final hifz = HifzService.instance;
    final isCurrent = QuranAudioService.instance.current == pos;
    final spans = _tajweed![ayahNum] ?? const <TajweedSpan>[];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isCurrent
          ? AppTheme.primaryGreen.withOpacity(0.12)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAyahActions(pos, ayah.textArabic),
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
                  tajweedOn: hifz.settings.tajweed,
                  fontSize: hifz.settings.mushafFontSize,
                  fontFamily: quranFontFamily(),
                ),
              ),
              const SizedBox(width: 10),
              _ayahNumberBadge(ayahNum, hifz.statusOf(pos)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ayahNumberBadge(int ayahNum, int? status) {
    final color = hifzStatusColor(status);
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '﴿${toArabicDigits(ayahNum)}﴾',
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _showAyahActions(QuranPos pos, String ayahText) async {
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
                  spans: _tajweed![pos.ayah] ?? const <TajweedSpan>[],
                  ruleColors: _ruleColors!,
                  tajweedOn: false,
                  fontSize: 20,
                  fontFamily: quranFontFamily(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline, color: AppTheme.primaryGreen),
                title: const Text('تشغيل التلاوة (تكرار حسب الإعدادات)'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  QuranAudioService.instance.playAyah(pos);
                },
              ),
              ListTile(
                leading: const Icon(Icons.thumb_up_alt_outlined, color: AppTheme.successGreen),
                title: const Text('أتقنتُها / حفظتَها'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  HifzService.instance.markMemorized([pos]);
                  _snack('سُجّلت الآية كمتقنة');
                },
              ),
              ListTile(
                leading: const Icon(Icons.replay, color: Color(0xFF3B85C2)),
                title: const Text('أحتاج مراجعتها'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showReviewSheet(context, pos);
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz_outlined, color: AppTheme.gold),
                title: const Text('تسميع ذاتي لهذه الآية'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HifzTestScreen(
                        initialSurah: pos.surah,
                        initialAyah: pos.ayah,
                      ),
                    ),
                  );
                },
              ),
              if (HifzService.instance.hasStatus(pos))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppTheme.dangerRed),
                  title: const Text('حذف التسجيل لهذه الآية'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    HifzService.instance.clearStatus(pos);
                    _snack('حُذف تسجيل الآية');
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