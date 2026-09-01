import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';

class AsmaAlHusnaScreen extends StatefulWidget {
  const AsmaAlHusnaScreen({super.key});

  @override
  State<AsmaAlHusnaScreen> createState() => _AsmaAlHusnaScreenState();
}

class _AsmaAlHusnaScreenState extends State<AsmaAlHusnaScreen> {
  bool _showMeanings = false;

  static const List<Map<String, String>> _names = [
    {'ar': 'الله', 'en': 'Allah', 'desc': 'الاسم الأعظم الجامع لجميع صفات الكمال'},
    {'ar': 'الرَّحْمَن', 'en': 'The Most Merciful', 'desc': 'الذي وسعت رحمته كل شيء'},
    {'ar': 'الرَّحِيم', 'en': 'The Especially Merciful', 'desc': 'الذي خصّ رحمته بالمؤمنين'},
    {'ar': 'المَلِك', 'en': 'The King', 'desc': 'المالك المتصرف بملكه كيف يشاء'},
    {'ar': 'القُدُّوس', 'en': 'The Holy', 'desc': 'المنزه عن كل نقص'},
    {'ar': 'السَّلاَم', 'en': 'The Source of Peace', 'desc': 'السالم من كل عيب ونقص'},
    {'ar': 'المُؤْمِن', 'en': 'The Giver of Security', 'desc': 'المصدق لرسله بالآيات'},
    {'ar': 'المُهَيْمِن', 'en': 'The Guardian', 'desc': 'الرقيب الحافظ لكل شيء'},
    {'ar': 'العَزِيز', 'en': 'The Almighty', 'desc': 'الغالب الذي لا يُغلب'},
    {'ar': 'الجَبَّار', 'en': 'The Compeller', 'desc': 'الذي يجبر كسر عباده'},
    {'ar': 'المُتَكَبِّر', 'en': 'The Supreme', 'desc': 'المتعالي عن صفات الخلق'},
    {'ar': 'الخَالِق', 'en': 'The Creator', 'desc': 'المُبدع لكل موجود'},
    {'ar': 'البَارِئ', 'en': 'The Evolver', 'desc': 'المُقدر للأشياء على مقدار'},
    {'ar': 'المُصَوِّر', 'en': 'The Fashioner', 'desc': 'المعطي لكل شيء صورته'},
    {'ar': 'الغَفَّار', 'en': 'The Repeatedly Forgiving', 'desc': 'كثير المغفرة لذنوب عباده'},
    {'ar': 'القَهَّار', 'en': 'The Subduer', 'desc': 'الغالب الذي قهر كل شيء'},
    {'ar': 'الوَهَّاب', 'en': 'The Bestower', 'desc': 'الكثير العطيّة بلا مقابل'},
    {'ar': 'الرَّزَّاق', 'en': 'The Provider', 'desc': 'الذي يرزق عباده كلهم'},
    {'ar': 'الفَتَّاح', 'en': 'The Opener', 'desc': 'الذي يفتح أبواب الخير'},
    {'ar': 'العَلِيم', 'en': 'The All-Knowing', 'desc': 'المحيط علمه بكل شيء'},
    {'ar': 'القَابِض', 'en': 'The Restrainer', 'desc': 'القابض للأرواح والقلوب'},
    {'ar': 'البَاسِط', 'en': 'The Reliever', 'desc': 'الباسط الرزق والرحمة'},
    {'ar': 'الخَافِض', 'en': 'The Abaser', 'desc': 'الخافض من شاء من عباده'},
    {'ar': 'الرَّافِع', 'en': 'The Exalter', 'desc': 'الرافع من شاء من عباده'},
    {'ar': 'المُعِزّ', 'en': 'The Giver of Honor', 'desc': 'المعز من شاء بكرمه'},
    {'ar': 'المُذِلّ', 'en': 'The Giver of Dishonor', 'desc': 'المذل من شاء من عباده'},
    {'ar': 'السَّمِيع', 'en': 'The All-Hearing', 'desc': 'الذي لا يخفى عليه مسموع'},
    {'ar': 'البَصِير', 'en': 'The All-Seeing', 'desc': 'الذي يبصر كل شيء'},
    {'ar': 'الحَكَم', 'en': 'The Judge', 'desc': 'فصل بين الخلق بالعدل'},
    {'ar': 'العَدْل', 'en': 'The Just', 'desc': 'المنزه عن الظلم'},
    {'ar': 'اللَّطِيف', 'en': 'The Subtle', 'desc': 'الرفيق بعباده في تدبيره'},
    {'ar': 'الخَبِير', 'en': 'The Aware', 'desc': 'العليم بدقائق الأمور'},
    {'ar': 'الحَلِيم', 'en': 'The Forbearing', 'desc': 'الذي لا يعجل بالعقوبة'},
    {'ar': 'العَظِيم', 'en': 'The Magnificent', 'desc': 'الجامع لصفات العظمة'},
    {'ar': 'الغَفُور', 'en': 'The Forgiving', 'desc': 'الذي يغفر الذنوب مهما كبرت'},
    {'ar': 'الشَّكُور', 'en': 'The Appreciative', 'desc': 'يُثيب على القليل كثيراً'},
    {'ar': 'العَلِيّ', 'en': 'The Most High', 'desc': 'منتهى العلو بلا حد'},
    {'ar': 'الكَبِير', 'en': 'The Greatest', 'desc': 'الجامع لصفات الجلال'},
    {'ar': 'الحَفِيظ', 'en': 'The Preserver', 'desc': 'الحافظ لكل شيء، الذي لا يضيع عنده شيء'},
    {'ar': 'المُقِيت', 'en': 'The Sustainer', 'desc': 'الكافي لخلقه'},
    {'ar': 'الحَسِيب', 'en': 'The Reckoner', 'desc': 'المحاسب للعباد'},
    {'ar': 'الجَلِيل', 'en': 'The Majestic', 'desc': 'الجامع لصفات الجلال'},
    {'ar': 'الكَرِيم', 'en': 'The Generous', 'desc': 'الجواد المعطي الذي لا ينفد'},
    {'ar': 'الرَّقِيب', 'en': 'The Watchful', 'desc': 'الرقيب على عباده'},
    {'ar': 'المُجِيب', 'en': 'The Responder', 'desc': 'المجيب لدعاء المضطرين'},
    {'ar': 'الوَاسِع', 'en': 'The All-Encompassing', 'desc': 'الذي وسع علمه ورحمته كل شيء'},
    {'ar': 'الحَكِيم', 'en': 'The Wise', 'desc': 'الذي حكمته في خلقه'},
    {'ar': 'الوَدُود', 'en': 'The Loving', 'desc': 'المحب لعباده الصالحين'},
    {'ar': 'المَجِيد', 'en': 'The Glorious', 'desc': 'الكثير الخير والعطاء'},
    {'ar': 'البَاعِث', 'en': 'The Resurrector', 'desc': 'يُحيي الموتى'},
    {'ar': 'الشَّهِيد', 'en': 'The Witness', 'desc': 'المحيط علمه بأعمال العباد'},
    {'ar': 'الحَقّ', 'en': 'The Truth', 'desc': 'الصادق في أقواله وأفعاله'},
    {'ar': 'الوَكِيل', 'en': 'The Trustee', 'desc': 'الكفيل بأرزاق عباده'},
    {'ar': 'القَوِيّ', 'en': 'The Strong', 'desc': 'الذي لا يُقهَر قوته'},
    {'ar': 'المَتِين', 'en': 'The Firm', 'desc': 'شديد القوة'},
    {'ar': 'الوَلِيّ', 'en': 'The Friend/Protector', 'desc': 'الناصر والمحب لعباده'},
    {'ar': 'الحَمِيد', 'en': 'The Praiseworthy', 'desc': 'المحمود بصفات الكمال'},
    {'ar': 'المُحْصِي', 'en': 'The Counter', 'desc': 'العليم بعدد كل شيء'},
    {'ar': 'المُبْدِئ', 'en': 'The Originator', 'desc': 'مبدأ الخلق'},
    {'ar': 'المُعِيد', 'en': 'The Restorer', 'desc': 'يعيد الخلق كما بدأه'},
    {'ar': 'المُحْيِي', 'en': 'The Giver of Life', 'desc': 'يُحيي الموتى بإرادته'},
    {'ar': 'المُمِيت', 'en': 'The Bringer of Death', 'desc': 'يُميت الأحياء بإرادته'},
    {'ar': 'الحَيّ', 'en': 'The Ever-Living', 'desc': 'الحي الذي لا يموت'},

    {'ar': 'القَيُّوم', 'en': 'The Sustainer', 'desc': 'القائم بنفسه الذي لا يحتاج إلى غيره'},
    {'ar': 'الوَاجِد', 'en': 'The Finder', 'desc': 'الذي لا يلتمس فيجد'},
    {'ar': 'المَاجِد', 'en': 'The Noble', 'desc': 'الكريم العظيم'},
    {'ar': 'الوَاحِد', 'en': 'The One', 'desc': 'المنفرد في ذاته وصفاته'},
    {'ar': 'الصَّمَد', 'en': 'The Eternal', 'desc': 'الذي لا يحتاج إلى أحد'},
    {'ar': 'القَادِر', 'en': 'The Able', 'desc': 'القادر على كل شيء'},
    {'ar': 'المُقْتَدِر', 'en': 'The Capable', 'desc': 'القادر الذي قدر كل شيء'},
    {'ar': 'المُقَدِّم', 'en': 'The Expediter', 'desc': 'يُقدّم من يشاء'},
    {'ar': 'المُؤَخِّر', 'en': 'The Delayer', 'desc': 'يُؤخّر من يشاء'},
    {'ar': 'الأوَّل', 'en': 'The First', 'desc': 'الذي لم يسبقه شيء'},
    {'ar': 'الآخِر', 'en': 'The Last', 'desc': 'الذي لا يبقى بعده شيء'},
    {'ar': 'الظَّاهِر', 'en': 'The Manifest', 'desc': 'الذي دلّ على ذاته بخلقه'},
    {'ar': 'البَاطِن', 'en': 'The Hidden', 'desc': 'الذي لا تدركه العيون بالمشاهدة'},
    {'ar': 'الوَالِي', 'en': 'The Governor', 'desc': 'المالك الذي لا يُجار عليه'},
    {'ar': 'المُتَعَالِي', 'en': 'The Exalted', 'desc': 'المتعالي عن صفات الخلق'},
    {'ar': 'البَرّ', 'en': 'The Source of Goodness', 'desc': 'الكثير الخير'},
    {'ar': 'التَّوَّاب', 'en': 'The Acceptor of Repentance', 'desc': 'يُقبل التوبة على عباده'},
    {'ar': 'المُنْتَقِم', 'en': 'The Avenger', 'desc': 'يأخذ الظالمين على ظلمهم'},
    {'ar': 'العَفُوّ', 'en': 'The Pardoner', 'desc': 'الذي يُعفو عن الذنوب'},
    {'ar': 'الرَّؤُوف', 'en': 'The Compassionate', 'desc': 'الرحيم بعباده رحمة بالمؤمنين'},
    {'ar': 'مَالِكُ المُلْك', 'en': 'The Owner of Sovereignty', 'desc': 'مالك كل شيء'},
    {'ar': 'ذُو الجَلاَلِ وَالإِكْرَام', 'en': 'The Lord of Majesty and Honor', 'desc': 'الجامع للجلال والإكرام'},
    {'ar': 'المُقْسِط', 'en': 'The Equitable', 'desc': 'العادل في حكمه'},
    {'ar': 'الجَامِع', 'en': 'The Gatherer', 'desc': 'يجمع الخلق يوم القيامة'},
    {'ar': 'الغَنِيّ', 'en': 'The Rich', 'desc': 'الذي لا يحتاج إلى شيء'},
    {'ar': 'المُغْنِي', 'en': 'The Enricher', 'desc': 'يُغني من يشاء'},
    {'ar': 'المَانِع', 'en': 'The Withholder', 'desc': 'يمنع من يشاء بحكمته'},
    {'ar': 'الضَّارّ', 'en': 'The Harmer', 'desc': 'يضرّ من يشاء بحكمته'},
    {'ar': 'النَّافِع', 'en': 'The Benefiter', 'desc': 'ينفع من يشاء بكرمه'},
    {'ar': 'النُّور', 'en': 'The Light', 'desc': 'المنور للسماوات والأرض'},
    {'ar': 'الهَادِي', 'en': 'The Guide', 'desc': 'يهدي عباده إلى الصراط المستقيم'},
    {'ar': 'البَدِيع', 'en': 'The Incomparable', 'desc': 'الخالق على غير مثال'},
    {'ar': 'البَاقِي', 'en': 'The Everlasting', 'desc': 'الدائم الذي لا يفنى'},
    {'ar': 'الوَارِث', 'en': 'The Inheritor', 'desc': 'الباقي بعد فناء الخلق'},
    {'ar': 'الرَّشِيد', 'en': 'The Guide to the Right Path', 'desc': 'يهدي إلى الرشاد'},
    {'ar': 'الصَّبُور', 'en': 'The Patient', 'desc': 'الذي لا يعجل بالعقوبة'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسماء الله الحسنى'),
        actions: [
          IconButton(
            icon: Icon(_showMeanings ? Icons.visibility_off : Icons.visibility),
            tooltip: _showMeanings ? 'إخفاء المعاني' : 'إظهار المعاني',
            onPressed: () => setState(() => _showMeanings = !_showMeanings),
          ),
        ],
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
            english: name['en']!,
            description: name['desc']!,
            showMeaning: _showMeanings,
          );
        },
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  final int index;
  final String arabic;
  final String english;
  final String description;
  final bool showMeaning;

  const _NameCard({
    required this.index,
    required this.arabic,
    required this.english,
    required this.description,
    required this.showMeaning,
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
              if (showMeaning) ...[
                const SizedBox(height: 6),
                Text(
                  english,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
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
              const SizedBox(height: 12),
              Text(
                english,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[700],
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
