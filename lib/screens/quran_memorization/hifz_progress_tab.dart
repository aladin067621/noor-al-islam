import 'package:flutter/material.dart';
import '../../models/quran_models.dart';
import '../../services/hifz_service.dart';
import '../../services/quran_audio_service.dart';
import '../../services/quran_data_service.dart';
import '../../utils/theme.dart';
import '../../widgets/tajweed_text.dart';
import 'hifz_widgets.dart';

/// تبويب التقدم — إحصاءات الحفظ وآخر 7 أيام وشبكة السور
class HifzProgressTab extends StatefulWidget {
  const HifzProgressTab({super.key});

  @override
  State<HifzProgressTab> createState() => _HifzProgressTabState();
}

class _HifzProgressTabState extends State<HifzProgressTab> {
  List<QuranSurahMeta>? _metas;

  @override
  void initState() {
    super.initState();
    QuranDataService.instance.loadSurahsMeta().then((m) {
      if (mounted) setState(() => _metas = m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hifz = HifzService.instance;
    return AnimatedBuilder(
      animation: hifz,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _planCard(hifz),
          const SizedBox(height: 10),
          _dueCard(hifz),
          const SizedBox(height: 10),
          _statsGrid(hifz),
          const SizedBox(height: 14),
          _weekChart(hifz),
          const SizedBox(height: 14),
          Text('تقدم السور',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen)),
          const SizedBox(height: 8),
          if (_metas == null)
            const Center(child: CircularProgressIndicator())
          else
            for (final s in _metas!) _surahProgressTile(hifz, s),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _planCard(HifzService hifz) {
    final goal = hifz.dailyNewGoal;
    final done = hifz.todayNew;
    final frac = goal == 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('خطة اليوم', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'جديدة: ${toArabicDigits(done)} / ${toArabicDigits(goal)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                Text('مراجعات: ${toArabicDigits(hifz.todayReviews)}',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              done >= goal
                  ? 'أتممت هدفك اليوم — استمر في المراجعة يثبّت الحفظ'
                  : 'بقي ${toArabicDigits(goal - done)} آية جديدة لتحقيق هدف اليوم',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dueCard(HifzService hifz) {
    final due = hifz.dueList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 20, color: AppTheme.gold),
                const SizedBox(width: 6),
                Text(
                  'مستحقة المراجعة اليوم — ${toArabicDigits(due.length)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (due.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('لا آيات مستحقة اليوم — أحسنت',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              )
            else ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in due)
                    ActionChip(
                      avatar: Icon(Icons.mic, size: 15, color: AppTheme.primaryGreen),
                      label: Text(
                          '${toArabicDigits(p.surah)}:${toArabicDigits(p.ayah)}'),
                      onPressed: () => _dueAyahActions(p),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _dueAyahActions(QuranPos p) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'مراجعة آية ${toArabicDigits(p.ayah)} — سورة ${toArabicDigits(p.surah)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  QuranAudioService.instance.playAyah(p);
                },
                icon: const Icon(Icons.headphones),
                label: const Text('استمع للقارئ'),
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _reviewQuick(p);
                },
                icon: const Icon(Icons.rate_review),
                label: const Text('قيّم مراجعتي'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reviewQuick(QuranPos p) async {
    await showReviewSheet(context, p);
  }

  Widget _statsGrid(HifzService hifz) {
    final cells = [
      ['المتقن', toArabicDigits(hifz.totalMemorized), 1],
      ['قيد المراجعة', toArabicDigits(hifz.totalReview), 2],
      ['سلسلة الأيام', toArabicDigits(hifz.streak), null],
      ['جديدة اليوم', toArabicDigits(hifz.todayNew), 1],
      ['مراجعات اليوم', toArabicDigits(hifz.todayReviews), 2],
      ['تسميع اليوم', toArabicDigits(hifz.todayTests), null],
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.15,
      children: [
        for (final c in cells)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c[1] as String,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: hifzStatusColor(c[2] as int?))),
                  const SizedBox(height: 4),
                  Text(c[0] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _weekChart(HifzService hifz) {
    final days = hifz.last7Days();
    final maxC =
        days.map((d) => d['count'] as int).fold(0, (a, b) => a > b ? a : b);
    String shortDate(String d) {
      final p = d.split('-');
      return '${toArabicDigits(int.tryParse(p[1]) ?? 0)}/${toArabicDigits(int.tryParse(p[2]) ?? 0)}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('النشاط آخر 7 أيام',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              toArabicDigits(d['count'] as int) == '٠'
                                  ? ''
                                  : toArabicDigits(d['count'] as int),
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.primaryGreen),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              height: maxC == 0
                                  ? 3
                                  : 50.0 *
                                      (d['count'] as int) /
                                      maxC,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(
                                    (d['count'] as int) == 0 ? 0.15 : 0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(shortDate(d['date'] as String),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _surahProgressTile(HifzService hifz, QuranSurahMeta s) {
    final mem = hifz.memCountOfSurah(s.id);
    final frac = s.numberOfAyahs == 0 ? 0.0 : mem / s.numberOfAyahs;

    return Card(
      child: ListTile(
        dense: true,
        leading: Text(
          '${toArabicDigits(s.id)}. ${s.nameArabic}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 4,
            backgroundColor: Colors.grey.shade300,
            color: frac >= 1.0
                ? AppTheme.successGreen
                : (frac > 0 ? const Color(0xFF3B85C2) : Colors.grey.shade400),
          ),
        ),
        subtitle: Text('${toArabicDigits(mem)} / ${toArabicDigits(s.numberOfAyahs)}',
            style: const TextStyle(fontSize: 11)),
        trailing: IconButton(
          icon: const Icon(Icons.tune),
          tooltip: 'حالات الآيات',
          onPressed: () => _showSurahStatuses(s),
        ),
      ),
    );
  }

  void _showSurahStatuses(QuranSurahMeta s) {
    final hifz = HifzService.instance;
    final pos = hifz.positionsOf(s.id);
    if (pos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('لا توجد آيات مُسجّلة في هذه السورة'),
          duration: Duration(seconds: 2)));
      return;
    }
    pos.sort((a, b) => a.ayah.compareTo(b.ayah));
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('سورة ${s.nameArabic} — حالات الآيات المسجّلة',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in pos)
                        ActionChip(
                          avatar: CircleAvatar(
                            radius: 9,
                            backgroundColor:
                                hifzStatusColor(hifz.statusOf(p)).withOpacity(0.5),
                          ),
                          label: Text(toArabicDigits(p.ayah)),
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _ayahOptions(p);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ayahOptions(QuranPos p) async {
    final hifz = HifzService.instance;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'آية ${toArabicDigits(p.ayah)} — سورة ${toArabicDigits(p.surah)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.thumb_up_alt_outlined,
                    color: AppTheme.successGreen),
                title: const Text('متقنة'),
                onTap: () => Navigator.pop(sheetContext, 'mem'),
              ),
              ListTile(
                leading: const Icon(Icons.replay, color: Color(0xFF3B85C2)),
                title: const Text('مراجعة'),
                onTap: () => Navigator.pop(sheetContext, 'rev'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.dangerRed),
                title: const Text('حذف التسجيل'),
                onTap: () => Navigator.pop(sheetContext, 'del'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'mem':
        await hifz.markMemorized([p]);
        break;
      case 'rev':
        await showReviewSheet(context, p);
        break;
      case 'del':
        await hifz.clearStatus(p);
        break;
    }
  }
}