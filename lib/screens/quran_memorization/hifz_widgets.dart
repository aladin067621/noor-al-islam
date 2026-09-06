import 'package:flutter/material.dart';
import '../../models/quran_models.dart';
import '../../services/hifz_service.dart';
import '../../services/quran_audio_service.dart';
import '../../utils/theme.dart';
import '../../widgets/tajweed_text.dart';

/// لون حالة الحفظ للآية
Color hifzStatusColor(int? status) {
  switch (status) {
    case kStatusMemorized:
      return AppTheme.successGreen;
    case kStatusReview:
      return const Color(0xFF3B85C2);
    case kStatusOld:
      return AppTheme.dangerRed;
    default:
      return Colors.grey.shade400;
  }
}

/// اسم حالة الحفظ
String hifzStatusLabel(int? status) {
  switch (status) {
    case kStatusMemorized:
      return 'متقن';
    case kStatusReview:
      return 'مراجعة';
    case kStatusOld:
      return 'يحتاج إعادة';
    default:
      return 'جديد';
  }
}

/// لون الآية داخل المصحف وفق إعدادات الخط
String quranFontFamily() => HifzService.instance.settings.script == 'indopak'
    ? 'QuranIndopak'
    : 'QuranUthmani';

/// شريط مشغّل التلاوة أسفل شاشة حفظ القرآن
class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: QuranAudioService.instance,
      builder: (context, _) {
        final audio = QuranAudioService.instance;
        final cur = audio.current;
        if (cur == null) return const SizedBox.shrink();
        final hifz = HifzService.instance;

        return Material(
          elevation: 8,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF15201C)
              : Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سورة ${toArabicDigits(cur.surah)} — آية ${toArabicDigits(cur.ayah)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            audio.downloading
                                ? 'جارِ تحميل التلاوة…'
                                : (audio.playing ? '● جارِ التشغيل' : 'متوقف'),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'تكرار النطاق',
                    icon: Icon(hifz.settings.loopRange
                        ? Icons.repeat_one
                        : Icons.repeat),
                    color: hifz.settings.loopRange
                        ? AppTheme.primaryGreen
                        : null,
                    onPressed: () {
                      hifz.settings.loopRange = !hifz.settings.loopRange;
                      hifz.saveSettings();
                    },
                  ),
                  IconButton(
                    tooltip: 'السابقة',
                    icon: const Icon(Icons.skip_previous),
                    onPressed: audio.prev,
                  ),
                  IconButton(
                    tooltip: audio.playing ? 'إيقاف مؤقت' : 'متابعة',
                    icon: Icon(audio.playing ? Icons.pause : Icons.play_arrow),
                    onPressed: audio.playing ? audio.pause : audio.resume,
                  ),
                  IconButton(
                    tooltip: 'التالية',
                    icon: const Icon(Icons.skip_next),
                    onPressed: audio.next,
                  ),
                  IconButton(
                    tooltip: 'إيقاف',
                    icon: const Icon(Icons.stop),
                    onPressed: audio.stop,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ورقة تقييم المراجعة (سهل/جيد/صعب/نسيتها)
Future<void> showReviewSheet(BuildContext context, QuranPos pos) async {
  final hifz = HifzService.instance;
  final rating = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مراجعة آية ${toArabicDigits(pos.ayah)} — سورة ${toArabicDigits(pos.surah)}',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            for (final r in [
              ['easy', 'سهلة'],
              ['good', 'جيدة'],
              ['hard', 'صعبة'],
              ['forgot', 'نسيتها'],
            ])
              ListTile(
                leading: Icon(r[0] == 'forgot'
                    ? Icons.refresh
                    : Icons.check_circle_outline),
                title: Text(r[1]),
                onTap: () => Navigator.pop(context, r[0]),
              ),
          ],
        ),
      ),
    ),
  );
  if (rating == null || !context.mounted) return;
  // تمت خارج context هنا لتجنب استخدام context بعد pop
  await hifz.markReview(pos, rating);
}