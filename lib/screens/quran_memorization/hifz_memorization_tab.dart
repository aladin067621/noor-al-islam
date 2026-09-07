import 'package:flutter/material.dart';
import '../../models/quran_models.dart';
import '../../services/hifz_service.dart';
import '../../services/quran_audio_service.dart';
import '../../services/quran_data_service.dart';
import '../../utils/theme.dart';
import '../../widgets/tajweed_text.dart';
import 'hifz_widgets.dart';

/// تبويب جلسة الحفظ — نطاق آيات مع تكرار، وزر "أنهيت هذه الآية"
class HifzMemorizationTab extends StatefulWidget {
  const HifzMemorizationTab({super.key});

  @override
  State<HifzMemorizationTab> createState() => _HifzMemorizationTabState();
}

class _HifzMemorizationTabState extends State<HifzMemorizationTab> {
  List<QuranSurahMeta>? _metas;
  QuranSurah? _surah;
  Map<int, List<TajweedSpan>> _tajweedMap = {};
  Map<String, String> _ruleColors = {};
  int _startAyah = 1;
  int _endAyah = 1;
  int _repeat = 3;
  double _delay = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = QuranDataService.instance;
    final metas = await data.loadSurahsMeta();
    final hifz = HifzService.instance;
    if (!mounted) return;
    setState(() {
      _metas = metas;
      _repeat = hifz.settings.repeatPerAyah;
      _delay = hifz.settings.delaySec.toDouble();
    });
    await _loadSurahText(1);
  }

  Future<void> _loadSurahText(int id) async {
    final data = QuranDataService.instance;
    final s = await data.loadSurah(id);
    final tajweed = await data.loadTajweed(id);
    final colors = await data.loadRuleColors();
    if (!mounted) return;
    setState(() {
      _surah = s;
      _tajweedMap = tajweed;
      _ruleColors = colors;
      if (_startAyah > s.numberOfAyahs) _startAyah = s.numberOfAyahs;
      if (_endAyah < _startAyah) _endAyah = _startAyah;
      if (_endAyah > s.numberOfAyahs) _endAyah = s.numberOfAyahs;
    });
  }

  void _start() {
    final hifz = HifzService.instance;
    hifz.settings.repeatPerAyah = _repeat;
    hifz.settings.delaySec = _delay.round();
    hifz.saveSettings();
    final pos = QuranPos(_surah!.id, _startAyah);
    final end = QuranPos(_surah!.id, _endAyah);
    QuranAudioService.instance.playRange(pos, end);
  }

  @override
  Widget build(BuildContext context) {
    final hifz = HifzService.instance;
    final audio = QuranAudioService.instance;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طرق الحفظ المتداولة',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 10),
                _StrategyItem(
                  icon: Icons.repeat,
                  title: 'التكرار والتحبيث',
                  desc: 'استمع للآية مرات متعددة مع القارئ، ثم حاول ترديدها '
                      'دون مراجعة. كرر حتى تثبت في الذاكرة.',
                ),
                _StrategyItem(
                  icon: Icons.stairs,
                  title: 'الحفظ التراكمي',
                  desc: 'حفظ آية جديدة ثم راجع ما سبق فوراً: آية جديدة + مراجعة '
                      'الأمس + آية قبل أمس. هذا يثبّت الحفظ على المدى الطويل.',
                ),
                _StrategyItem(
                  icon: Icons.headphones,
                  title: 'الاستماع والمحاكاة',
                  desc: 'استمع باستمرار لتلاوة القارئ المفضل وحاكِ صوته. '
                      'هذا يُحسّن الترتيل ويُثبت النطق في الذاكرة.',
                ),
                _StrategyItem(
                  icon: Icons.edit_note,
                  title: 'الحفظ بالكتابة',
                  desc: 'اكتب الآية بيديك بعد الاستماع. الكتابة تُعزز '
                      'التثبيت وتساعد على تحسين الحفظ لمن يجد صعوبة بالسمع فقط.',
                ),
                _StrategyItem(
                  icon: Icons.school,
                  title: 'التسميع من الحفظ',
                  desc: 'أسمع الآية من ذاكرتك للشخص الآخر (زوج/صديق). '
                      'الإخراج من الذاكرة يُثبّت الحفظ أكثر من مجرد التكرار.',
                ),
                const SizedBox(height: 8),
                Text(
                  '﴿وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ﴾ [القمر: 17]',
                  style: TextStyle(
                      fontSize: 18,
                      height: 1.9,
                      fontFamily: quranFontFamily(),
                      color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جلسة الاستماع والتكرار',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 4),
                Text(
                  'اختر النطاق الجديد ثم ابدأ الجلسة؛ كل آية تتكرر بالعدد المحدد لتثبيت الحفظ.',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.7),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey('surah'),
                  value: _surah?.id,
                  decoration: const InputDecoration(
                    labelText: 'السورة',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: (_metas ?? [])
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text('سورة ${s.nameArabic}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _startAyah = 1);
                    _loadSurahText(v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _startAyah,
                        decoration: const InputDecoration(
                          labelText: 'من آية',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (var i = 1; i <= (_surah?.numberOfAyahs ?? 1); i++)
                            DropdownMenuItem(value: i, child: Text(toArabicDigits(i))),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _startAyah = v;
                            if (_endAyah < _startAyah) _endAyah = _startAyah;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _endAyah,
                        decoration: const InputDecoration(
                          labelText: 'إلى آية',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (var i = 1; i <= (_surah?.numberOfAyahs ?? 1); i++)
                            DropdownMenuItem(value: i, child: Text(toArabicDigits(i))),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _endAyah = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('تكرار كل آية:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _repeat.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: toArabicDigits(_repeat),
                        onChanged: (v) => setState(() => _repeat = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        toArabicDigits(_repeat),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('فاصل بين التكرارات (ث):'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _delay,
                        min: 0,
                        max: 10,
                        divisions: 20,
                        label: toArabicDigits(_delay.round()),
                        onChanged: (v) => setState(() => _delay = v),
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        toArabicDigits(_delay.round()),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _surah == null ? null : _start,
                    icon: const Icon(Icons.play_circle_fill),
                    label: Text(
                      'ابدأ جلسة الحفظ (${toArabicDigits(_startAyah)} – ${toArabicDigits(_endAyah)})',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: audio,
          builder: (context, _) {
            final cur = audio.current;
            if (cur == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'لم تبدأ جلسة بعد — اختر النطاق أعلاه وابدأ الاستماع.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final surah = _surah;
            final ayahText = surah?.ayahAt(cur.ayah).textArabic ?? '';
            final spans = _tajweedMap[cur.ayah] ?? const <TajweedSpan>[];
            final posIsMem = hifz.statusOf(cur) == kStatusMemorized;

            return Card(
              color: AppTheme.primaryGreen.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'سورة ${surah?.nameArabic ?? toArabicDigits(cur.surah)} — آية ${toArabicDigits(cur.ayah)}'
                      '${audio.downloading ? ' · جارِ تحميل التلاوة…' : (audio.errorMessage != null ? ' · تعذر التحميل — أعد المحاولة' : '')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TajweedText(
                      text: ayahText,
                      spans: spans,
                      ruleColors: _ruleColors,
                      tajweedOn: hifz.settings.tajweed,
                      fontSize: 26,
                      fontFamily: quranFontFamily(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: audio.playing ? null : audio.resume,
                            icon: Icon(audio.playing ? Icons.pause : Icons.play_arrow),
                            label: Text(audio.playing ? 'إيقاف مؤقت' : 'متابعة'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: audio.next,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('التالي'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        HifzService.instance.markMemorized([cur]);
                      },
                      icon: Icon(posIsMem ? Icons.check_circle : Icons.playlist_add_check),
                      label: Text(posIsMem
                          ? 'متقنة ✓'
                          : 'سجّلت هذه الآية للحفظ ✓'),
                    ),
                    if (!posIsMem)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'التسجيل للحفظ يبدأ مراجعاتها المتباعدة — لا تُحسب متقنة إلا بعد إتمام مراجعاتها.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StrategyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _StrategyItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}