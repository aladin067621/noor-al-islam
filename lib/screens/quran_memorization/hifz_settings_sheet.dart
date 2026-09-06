import 'package:flutter/material.dart';
import '../../services/hifz_service.dart';
import '../../services/quran_audio_service.dart';
import '../../utils/theme.dart';
import '../../widgets/tajweed_text.dart';

const List<List<String>> kReciters = [
  ['ar.husary', 'محمود خليل الحصري'],
  ['ar.alafasy', 'مشاري راشد العفاسي'],
  ['ar.minshawi', 'محمد صديق المنشاوي'],
  ['ar.abdulbasitmurattal', 'عبد الباسط عبد الصمد (مرتّل)'],
];

Future<void> showHifzSettingsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const HifzSettingsSheet(),
    );

class HifzSettingsSheet extends StatefulWidget {
  const HifzSettingsSheet({super.key});

  @override
  State<HifzSettingsSheet> createState() => _HifzSettingsSheetState();
}

class _HifzSettingsSheetState extends State<HifzSettingsSheet> {
  late HifzSettings _s;
  double _fontSize = 26;

  @override
  void initState() {
    super.initState();
    _s = HifzService.instance.settings;
    _fontSize = _s.mushafFontSize;
  }

  void _update() {
    _s.mushafFontSize = _fontSize;
    HifzService.instance.saveSettings();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إعدادات قسم حفظ القرآن',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _s.reciter,
                decoration: const InputDecoration(
                  labelText: 'القارئ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final r in kReciters)
                    DropdownMenuItem(value: r[0], child: Text(r[1])),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  await QuranAudioService.instance.setReciter(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 6),
              Text(
                'تُنزَّل الآية مرة واحدة ثم تُشغَّل محليًا دون اتصال. التخزين للاستخدام الشخصي/التعليمي فقط.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Text('تكرار كل آية أثناء الحفظ')),
                  Text(toArabicDigits(_s.repeatPerAyah),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _s.repeatPerAyah.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) {
                  _s.repeatPerAyah = v.round();
                  _update();
                },
              ),
              Row(
                children: [
                  const Expanded(child: Text('فاصل بين التكرارات (ثوانٍ)')),
                  Text(toArabicDigits(_s.delaySec),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _s.delaySec.toDouble(),
                min: 0,
                max: 10,
                divisions: 20,
                onChanged: (v) {
                  _s.delaySec = v.round();
                  _update();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تكرار نطاق الحفظ تلقائيًا'),
                value: _s.loopRange,
                onChanged: (v) {
                  _s.loopRange = v;
                  _update();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ألوان التجويد'),
                value: _s.tajweed,
                onChanged: (v) {
                  _s.tajweed = v;
                  _update();
                },
              ),
              Row(
                children: [
                  const Expanded(child: Text('رسم الخط')),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'uthmani', label: Text('عثماني')),
                      ButtonSegment(
                          value: 'indopak', label: Text('هندي')),
                    ],
                    selected: {_s.script},
                    onSelectionChanged: (set) {
                      _s.script = set.first;
                      _update();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Expanded(child: Text('حجم الخط')), 
                  Text('${toArabicDigits(_fontSize.round())}px',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _fontSize,
                min: 20,
                max: 40,
                divisions: 20,
                onChanged: (v) {
                  _fontSize = v;
                  _update();
                },
              ),
              const SizedBox(height: 4),
              Text(
                'مصدر النص: مصحف حفص (Quran-Tajweed-Engine) — مصدر الصوت: alquran.cloud · Quran.com',
                style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}