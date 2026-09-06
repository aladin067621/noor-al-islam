import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/quran_models.dart';
import '../../services/hifz_service.dart';
import '../../services/quran_audio_service.dart';
import '../../services/quran_data_service.dart';
import '../../utils/theme.dart';
import '../../widgets/tajweed_text.dart';
import 'hifz_widgets.dart';

/// التسميع الذاتي — اختبار يدوي بإظهار/إخفاء النص، دون أي تحليل صوتي.
/// يُعرض داخل تبويب (HifzTestTab) أو كشاشة مستقلة لآية واحدة (HifzTestScreen).
class HifzTestScreen extends StatefulWidget {
  final int? initialSurah;
  final int? initialAyah;

  const HifzTestScreen({super.key, this.initialSurah, this.initialAyah});

  @override
  State<HifzTestScreen> createState() => HifzTestScreenState();
}

class HifzTestScreenState extends State<HifzTestScreen> {
  int _mode = 0; // 0 سورة كاملة · 1 ما بعدها؟ · 2 من محفوظاتي
  bool get _embedded => widget.initialSurah == null;

  @override
  Widget build(BuildContext context) {
    final body = _TestBody(
      key: ValueKey('m$_mode'),
      mode: _mode,
      initialSurah: widget.initialSurah ?? 1,
      initialAyah: widget.initialAyah ?? 1,
      onModeChanged: (m) => setState(() => _mode = m),
    );
    if (_embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('تسميع ذاتي')),
      body: body,
    );
  }
}

/// نسخة داخل تبويب (بدون صندوق)
class HifzTestTab extends StatefulWidget {
  const HifzTestTab({super.key});

  @override
  State<HifzTestTab> createState() => _HifzTestTabState();
}

class _HifzTestTabState extends State<HifzTestTab> {
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    return _TestBody(
      key: ValueKey('m$_mode'),
      mode: _mode,
      onModeChanged: (m) => setState(() => _mode = m),
    );
  }
}

class _TestBody extends StatefulWidget {
  final int mode;
  final int? initialSurah;
  final int? initialAyah;
  final ValueChanged<int> onModeChanged;

  const _TestBody({
    super.key,
    required this.mode,
    this.initialSurah,
    this.initialAyah,
    required this.onModeChanged,
  });

  @override
  State<_TestBody> createState() => _TestBodyState();
}

class _TestBodyState extends State<_TestBody> {
  List<QuranSurahMeta>? _metas;
  final Map<int, QuranSurah> _textCache = {};
  Map<int, List<TajweedSpan>> _tajweedMap = {};
  Map<String, String> _ruleColors = {};
  int? _tajweedSurah;

  int _surahId = 1;
  int _index = 1; // مع index+1 للتسلسل
  int _memStart = 1;
  bool _revealed = false;

  void _listen() {
    QuranAudioService.instance.playAyah(_targetPos);
  }

  @override
  void initState() {
    super.initState();
    _index = 1;
    _surahId = widget.initialSurah ?? 1;
    _memStart = widget.initialAyah ?? 1;
    _load();
  }

  Future<void> _load() async {
    final data = QuranDataService.instance;
    final metas = await data.loadSurahsMeta();
    final colors = await data.loadRuleColors();
    if (!mounted) return;
    setState(() {
      _metas = metas;
      _ruleColors = colors;
    });
    await _preload(widget.initialSurah ?? 1);
  }

  Future<void> _preload(int id) async {
    final data = QuranDataService.instance;
    if (!_textCache.containsKey(id)) {
      final s = await data.loadSurah(id);
      if (!mounted) return;
      setState(() => _textCache[id] = s);
    }
    if (widget.mode == 0 && _tajweedSurah != id) {
      final t = await data.loadTajweed(id);
      if (mounted) {
        setState(() {
          _tajweedMap = t;
          _tajweedSurah = id;
        });
      }
    }
  }

  QuranSurah? get _surah => _textCache[_surahId];

  int get _ayahCount => _surah?.numberOfAyahs ?? 1;

  /// الآية المدارة في الاختبار (في "ما بعدها؟" هي الآية التالية الصريحة)
  QuranPos get _targetPos => QuranPos(
      _surahId, widget.mode == 1 ? _index + 1 : _index);

  bool get _atEnd => widget.mode == 1 && _index >= _ayahCount;

  Future<void> _pickSurah() async {
    final metas = _metas ?? [];
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: metas.length,
          itemBuilder: (context, i) => ListTile(
            title: Text('سورة ${metas[i].nameArabic}'),
            subtitle: Text('${toArabicDigits(metas[i].numberOfAyahs)} آية'),
            onTap: () => Navigator.pop(sheetContext, metas[i].id),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _surahId = picked;
      _index = 1;
      _revealed = false;
      _preload(picked);
    });
  }

  Future<void> _pickStartAyah() async {
    final n = _surah?.numberOfAyahs ?? 1;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView.builder(
          itemCount: n,
          itemBuilder: (context, i) => ListTile(
            leading: Text(toArabicDigits(i + 1)),
            title: const Text(''),
            onTap: () => Navigator.pop(sheetContext, i + 1),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _memStart = picked;
      _index = picked;
      _revealed = false;
    });
  }

  Future<void> _markRate(QuranPos pos) async {
    await showReviewSheet(context, pos);
    _advance();
  }

  void _advance() {
    if (!mounted) return;
    setState(() {
      _revealed = false;
      if (widget.mode == 0) {
        if (_index < _ayahCount) _index++;
      } else {
        _index++;
      }
    });
  }

  void _nextRandom() {
    final pos = HifzService.instance.memorizedPositions();
    if (pos.isEmpty) {
      setState(() => _revealed = true);
      _snack('لا توجد آيات محفوظة بعد — احفظ أولاً من تبويب الحفظ');
      return;
    }
    final r = pos[Random().nextInt(pos.length)];
    setState(() {
      _surahId = r.surah;
      _index = r.ayah;
      _revealed = false;
      _preload(r.surah);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hifz = HifzService.instance;
    return Column(
      children: [
        _modeSelector(),
        Expanded(
          child: _surah == null
              ? const Center(child: CircularProgressIndicator())
              : AnimatedBuilder(
                  animation: hifz,
                  builder: (context, _) => ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _sessionHeader(),
                      const SizedBox(height: 10),
                      _areaCard(),
                      const SizedBox(height: 12),
                      _callsToAction(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _modeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Text('سورة'),
              selected: widget.mode == 0,
              onSelected: (_) => widget.onModeChanged(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: const Text('ما بعدها؟'),
              selected: widget.mode == 1,
              onSelected: (_) => widget.onModeChanged(1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: const Text('من محفوظاتي'),
              selected: widget.mode == 2,
              onSelected: (_) => widget.onModeChanged(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionHeader() {
    final s = _surah!;
    if (widget.mode == 2) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: _nextRandom,
              icon: const Icon(Icons.shuffle),
              label: const Text('آية عشوائية من محفوظاتي'),
            ),
          ),
        ],
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _pickSurah,
                icon: const Icon(Icons.menu_book_outlined),
                label: Text('سورة ${s.nameArabic}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            if (widget.mode == 1) ...[
              TextButton.icon(
                onPressed: _pickStartAyah,
                icon: const Icon(Icons.filter_1),
                label: Text('من آية ${toArabicDigits(_memStart)}'),
              ),
            ],
            Text(
              '${toArabicDigits(_index)} / ${toArabicDigits(_ayahCount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _areaCard() {
    final hifz = HifzService.instance;
    final s = _surah!;
    if (_atEnd) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'انتهت آيات السورة — أحسنت.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    final ayah = s.ayahAt(_targetPos.ayah);
    final tajweedOn = hifz.settings.tajweed;
    final spans = _tajweedMap[_targetPos.ayah];
    final title = widget.mode == 1
        ? _revealed
            ? 'الآية التالية'
            : 'ما بعد آية ${toArabicDigits(_index)}؟'
        : 'آية ${toArabicDigits(_index)}';
    final isMem =
        hifz.statusOf(_targetPos) == kStatusMemorized;

    return Card(
      color: _revealed ? AppTheme.primaryGreen.withOpacity(0.08) : null,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (isMem)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('محفوظة',
                        style: TextStyle(
                            color: AppTheme.successGreen, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (_revealed)
              TajweedText(
                text: ayah.textArabic,
                spans: spans ?? const <TajweedSpan>[],
                ruleColors: _ruleColors,
                tajweedOn: tajweedOn,
                fontSize: 28,
                fontFamily: quranFontFamily(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  widget.mode == 1
                      ? 'النص مخفي — أسمع آية ${toArabicDigits(_index)} من ذاكرتك، ثم اضغط «إظهار النص» لتتحقق من الآية التالية.'
                      : 'النص مخفي — حاول التسميع من ذاكرتك ثم اضغط «إظهار النص» للتحقق.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _callsToAction() {
    final hifz = HifzService.instance;
    final enabled = widget.mode != 2 ||
        hifz.memorizedPositions().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: enabled && !_revealed
              ? () => setState(() => _revealed = true)
              : null,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('إظهار النص'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _atEnd || !enabled ? null : () => _listen(),
          icon: const Icon(Icons.headphones),
          label: Text('استمع لآية ${toArabicDigits(_targetPos.ayah)} (${toArabicDigits(QuranAudioService.instance.repeatPerAyah)} مرات)'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _revealed
              ? () {
                  hifz.markTested(_targetPos);
                  _advance();
                }
              : null,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(widget.mode == 1 ? 'أسمعتُها — التالية ✓' : 'أسمعتُها ✓'),
        ),
        const SizedBox(height: 12),
        const Text('كيف كانت الآية؟ (تُسجَّل للمراجعة)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        for (final r in [
          ['easy', 'سهلة'],
          ['good', 'جيدة'],
          ['hard', 'صعبة'],
          ['forgot', 'نسيتها'],
        ])
          ListTile(
            dense: true,
            leading: Icon(
                r[0] == 'forgot' ? Icons.refresh : Icons.check_circle_outline,
                color: hifzStatusColor(r[0] == 'forgot' ? 3 : 2)),
            title: Text(r[1]),
            onTap: _revealed ? () => _markRate(_targetPos) : null,
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}