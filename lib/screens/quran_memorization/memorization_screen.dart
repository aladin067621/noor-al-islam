import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class MemorizationScreen extends StatelessWidget {
  const MemorizationScreen({super.key});

  static const _strategies = [
    {
      'icon': Icons.repeat,
      'title': 'التكرار المتباعد',
      'desc': 'احفظ 3 إلى 5 آيات يوميًا، مع مراجعة محفوظ الأسبوع السابق باستمرار لترسيخه في الذاكرة بعيدة المدى.',
    },
    {
      'icon': Icons.add_circle_outline,
      'title': 'طريقة الجمع (الإضافة التدريجية)',
      'desc': 'احفظ آية، ثم أضف الثانية واقرأهما معًا، ثم الثالثة... وهكذا، ثم راجع الكل دفعة واحدة.',
    },
    {
      'icon': Icons.lightbulb_outline,
      'title': 'الربط بالمعنى',
      'desc': 'اقرأ التفسير المختصر للآيات قبل حفظها، فالفهم يثبّت الحفظ ويعينك على التدبر.',
    },
    {
      'icon': Icons.today,
      'title': 'المراجعة اليومية',
      'desc': 'خصّص 10 دقائق لمراجعة القديم و10 دقائق لحفظ الجديد. الثبات على القليل خير من الكثير المنقطع.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حفظ القرآن')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  'استراتيجية الحفظ المنظم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  '﴿وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِنْ مُدَّكِرٍ﴾',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppTheme.quranFontFamily, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ..._strategies.map((s) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(s['icon'] as IconData, color: AppTheme.gold, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['title'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(s['desc'] as String,
                                style: const TextStyle(height: 1.8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 18),
          _buildAdviceSection(),
        ],
      ),
    );
  }

  Widget _buildAdviceSection() {
    const advice = [
      {
        'icon': Icons.bedtime_outlined,
        'title': 'النوم المبكر والكفاية من النوم',
        'desc': 'حافظ على نومك باكرًا ونم قسطًا كافيًا، فالعقل الصافي أنشط للحفظ وتركيز أسرع.',
      },
      {
        'icon': Icons.restaurant_outlined,
        'title': 'الاعتدال في الأكل',
        'desc': 'لا تسرف في الطعام؛ فكثرة الأكل تورث الكسل وتذهب النشاط وتعيق الحفظ والتركيز.',
      },
      {
        'icon': Icons.visibility_off_outlined,
        'title': 'غض البصر',
        'desc': 'غضّ بصرك عن المحرمات، فإنها تُظلم القلب وتُذهب نور الإيمان وتعيق حفظ القرآن.',
      },
      {
        'icon': Icons.cleaning_services_outlined,
        'title': 'صفاء القلب والخشوع',
        'desc': 'طهّر قلبك بالاستغفار وترك الذنوب، فالإخلاص والطهارة من أعظم أسباب التوفيق للحفظ.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نصائح تعين على الحفظ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...advice.map((a) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(a['icon'] as IconData, color: AppTheme.gold, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['title'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(a['desc'] as String,
                              style: const TextStyle(height: 1.8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
