import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';

class AsmaAlHusnaScreen extends StatelessWidget {
  const AsmaAlHusnaScreen({super.key});

  static const List<Map<String, String>> _names = [
    {'ar': 'الله', 'desc': 'الاسم الأعظم الجامع لجميع صفات الكمال'},
    {'ar': 'الرَّحْمَن', 'desc': 'الذي وسعت رحمته كل شيء'},
    {'ar': 'الرَّحِيم', 'desc': 'الذي خصّ رحمته بالمؤمنين'},
    {'ar': 'المَلِك', 'desc': 'المالك المتصرف بملكه كيف يشاء'},
    {'ar': 'القُدُّوس', 'desc': 'المنزه عن كل نقص'},
    {'ar': 'السَّلاَم', 'desc': 'السالم من كل عيب ونقص'},
    {'ar': 'المُؤْمِن', 'desc': 'المصدق لرسله بالآيات'},
    {'ar': 'المُهَيْمِن', 'desc': 'الرقيب الحافظ لكل شيء'},
    {'ar': 'العَزِيز', 'desc': 'الغالب الذي لا يُغلب'},
    {'ar': 'الجَبَّار', 'desc': 'الذي يجبر كسر عباده'},
    {'ar': 'المُتَكَبِّر', 'desc': 'المتعالي عن صفات الخلق'},
    {'ar': 'الخَالِق', 'desc': 'المُبدع لكل موجود'},
    {'ar': 'البَارِئ', 'desc': 'المُقدر للأشياء على مقدار'},
    {'ar': 'المُصَوِّر', 'desc': 'المعطي لكل شيء صورته'},
    {'ar': 'الغَفَّار', 'desc': 'كثير المغفرة لذنوب عباده'},
    {'ar': 'القَهَّار', 'desc': 'الغالب الذي قهر كل شيء'},
    {'ar': 'الوَهَّاب', 'desc': 'الكثير العطيّة بلا مقابل'},
    {'ar': 'الرَّزَّاق', 'desc': 'الذي يرزق عباده كلهم'},
    {'ar': 'الفَتَّاح', 'desc': 'الذي يفتح أبواب الخير'},
    {'ar': 'العَلِيم', 'desc': 'المحيط علمه بكل شيء'},
    {'ar': 'القَابِض', 'desc': 'القابض للأرواح والقلوب'},
    {'ar': 'البَاسِط', 'desc': 'الباسط الرزق والرحمة'},
    {'ar': 'الخَافِض', 'desc': 'الخافض من شاء من عباده'},
    {'ar': 'الرَّافِع', 'desc': 'الرافع من شاء من عباده'},
    {'ar': 'المُعِزّ', 'desc': 'المعز من شاء بكرمه'},
    {'ar': 'المُذِلّ', 'desc': 'المذل من شاء من عباده'},
    {'ar': 'السَّمِيع', 'desc': 'الذي لا يخفى عليه مسموع'},
    {'ar': 'البَصِير', 'desc': 'الذي يبصر كل شيء'},
    {'ar': 'الحَكَم', 'desc': 'فصل بين الخلق بالعدل'},
    {'ar': 'العَدْل', 'desc': 'المنزه عن الظلم'},
    {'ar': 'اللَّطِيف', 'desc': 'الرفيق بعباده في تدبيره'},
    {'ar': 'الخَبِير', 'desc': 'العليم بدقائق الأمور'},
    {'ar': 'الحَلِيم', 'desc': 'الذي لا يعجل بالعقوبة'},
    {'ar': 'العَظِيم', 'desc': 'الجامع لصفات العظمة'},
    {'ar': 'الغَفُور', 'desc': 'الذي يغفر الذنوب مهما كبرت'},
    {'ar': 'الشَّكُور', 'desc': 'يُثيب على القليل كثيراً'},
    {'ar': 'العَلِيّ', 'desc': 'منتهى العلو بلا حد'},
    {'ar': 'الكَبِير', 'desc': 'الجامع لصفات الجلال'},
    {'ar': 'الحَفِيظ', 'desc': 'الحافظ لكل شيء، الذي لا يضيع عنده شيء'},
    {'ar': 'المُقِيت', 'desc': 'الكافي لخلقه'},
    {'ar': 'الحَسِيب', 'desc': 'المحاسب للعباد'},
    {'ar': 'الجَلِيل', 'desc': 'الجامع لصفات الجلال'},
    {'ar': 'الكَرِيم', 'desc': 'الجواد المعطي الذي لا ينفد'},
    {'ar': 'الرَّقِيب', 'desc': 'الرقيب على عباده'},
    {'ar': 'المُجِيب', 'desc': 'المجيب لدعاء المضطرين'},
    {'ar': 'الوَاسِع', 'desc': 'الذي وسع علمه ورحمته كل شيء'},
    {'ar': 'الحَكِيم', 'desc': 'الذي حكمته في خلقه'},
    {'ar': 'الوَدُود', 'desc': 'المحب لعباده الصالحين'},
    {'ar': 'المَجِيد', 'desc': 'الكثير الخير والعطاء'},
    {'ar': 'البَاعِث', 'desc': 'يُحيي الموتى'},
    {'ar': 'الشَّهِيد', 'desc': 'المحيط علمه بأعمال العباد'},
    {'ar': 'الحَقّ', 'desc': 'الصادق في أقواله وأفعاله'},
    {'ar': 'الوَكِيل', 'desc': 'الكفيل بأرزاق عباده'},
    {'ar': 'القَوِيّ', 'desc': 'الذي لا يُقهَر قوته'},
    {'ar': 'المَتِين', 'desc': 'شديد القوة'},
    {'ar': 'الوَلِيّ', 'desc': 'الناصر والمحب لعباده'},
    {'ar': 'الحَمِيد', 'desc': 'المحمود بصفات الكمال'},
    {'ar': 'المُحْصِي', 'desc': 'العليم بعدد كل شيء'},
    {'ar': 'المُبْدِئ', 'desc': 'مبدأ الخلق'},
    {'ar': 'المُعِيد', 'desc': 'يعيد الخلق كما بدأه'},
    {'ar': 'المُحْيِي', 'desc': 'يُحيي الموتى بإرادته'},
    {'ar': 'المُمِيت', 'desc': 'يُميت الأحياء بإرادته'},
    {'ar': 'الحَيّ', 'desc': 'الحي الذي لا يموت'},
    {'ar': 'القَيُّوم', 'desc': 'القائم بنفسه الذي لا يحتاج إلى غيره'},
    {'ar': 'الوَاجِد', 'desc': 'الذي لا يلتمس فيجد'},
    {'ar': 'المَاجِد', 'desc': 'الكريم العظيم'},
    {'ar': 'الوَاحِد', 'desc': 'المنفرد في ذاته وصفاته'},
    {'ar': 'الصَّمَد', 'desc': 'الذي لا يحتاج إلى أحد'},
    {'ar': 'القَادِر', 'desc': 'القادر على كل شيء'},
    {'ar': 'المُقْتَدِر', 'desc': 'القادر الذي قدر كل شيء'},
    {'ar': 'المُقَدِّم', 'desc': 'يُقدّم من يشاء'},
    {'ar': 'المُؤَخِّر', 'desc': 'يُؤخّر من يشاء'},
    {'ar': 'الأوَّل', 'desc': 'الذي لم يسبقه شيء'},
    {'ar': 'الآخِر', 'desc': 'الذي لا يبقى بعده شيء'},
    {'ar': 'الظَّاهِر', 'desc': 'الذي دلّ على ذاته بخلقه'},
    {'ar': 'البَاطِن', 'desc': 'الذي لا تدركه العيون بالمشاهدة'},
    {'ar': 'الوَالِي', 'desc': 'المالك الذي لا يُجار عليه'},
    {'ar': 'المُتَعَالِي', 'desc': 'المتعالي عن صفات الخلق'},
    {'ar': 'البَرّ', 'desc': 'الكثير الخير'},
    {'ar': 'التَّوَّاب', 'desc': 'يُقبل التوبة على عباده'},
    {'ar': 'المُنْتَقِم', 'desc': 'يأخذ الظالمين على ظلمهم'},
    {'ar': 'العَفُوّ', 'desc': 'الذي يُعفو عن الذنوب'},
    {'ar': 'الرَّؤُوف', 'desc': 'الرحيم بعباده رحمة بالمؤمنين'},
    {'ar': 'مَالِكُ المُلْك', 'desc': 'مالك كل شيء'},
    {'ar': 'ذُو الجَلاَلِ وَالإِكْرَام', 'desc': 'الجامع للجلال والإكرام'},
    {'ar': 'المُقْسِط', 'desc': 'العادل في حكمه'},
    {'ar': 'الجَامِع', 'desc': 'يجمع الخلق يوم القيامة'},
    {'ar': 'الغَنِيّ', 'desc': 'الذي لا يحتاج إلى شيء'},
    {'ar': 'المُغْنِي', 'desc': 'يُغني من يشاء'},
    {'ar': 'المَانِع', 'desc': 'يمنع من يشاء بحكمته'},
    {'ar': 'الضَّارّ', 'desc': 'يضرّ من يشاء بحكمته'},
    {'ar': 'النَّافِع', 'desc': 'ينفع من يشاء بكرمه'},
    {'ar': 'النُّور', 'desc': 'المنور للسماوات والأرض'},
    {'ar': 'الهَادِي', 'desc': 'يهدي عباده إلى الصراط المستقيم'},
    {'ar': 'البَدِيع', 'desc': 'الخالق على غير مثال'},
    {'ar': 'البَاقِي', 'desc': 'الدائم الذي لا يفنى'},
    {'ar': 'الوَارِث', 'desc': 'الباقي بعد فناء الخلق'},
    {'ar': 'الرَّشِيد', 'desc': 'يهدي إلى الرشاد'},
    {'ar': 'الصَّبُور', 'desc': 'الذي لا يعجل بالعقوبة'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسماء الله الحسنى'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: _names.length,
        itemBuilder: (context, index) {
          final name = _names[index];
          return _NameCard(
            index: index + 1,
            arabic: name['ar']!,
            description: name['desc']!,
          );
        },
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  final int index;
  final String arabic;
  final String description;

  const _NameCard({
    required this.index,
    required this.arabic,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDetail(context);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryGreen.withOpacity(0.08),
                AppTheme.primaryGreen.withOpacity(0.02),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$index',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                arabic,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.quranFontFamily,
                  fontSize: arabic.length > 12 ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.2,
        maxChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$index',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                arabic,
                style: TextStyle(
                  fontFamily: AppTheme.quranFontFamily,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.quranFontFamily,
                    fontSize: 18,
                    color: AppTheme.darkGreen,
                    height: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
