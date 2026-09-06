/// نماذج القرآن لبيانات Quran-Tajweed-Engine (111لقراءة والحفظ)
class QuranSurahMeta {
  final int id;
  final String nameArabic;
  final int numberOfAyahs;
  final int pageStart;
  final int pageEnd;
  final int firstJuz;
  final int lastJuz;

  const QuranSurahMeta({
    required this.id,
    required this.nameArabic,
    required this.numberOfAyahs,
    required this.pageStart,
    required this.pageEnd,
    required this.firstJuz,
    required this.lastJuz,
  });

  factory QuranSurahMeta.fromJson(Map<String, dynamic> j) => QuranSurahMeta(
        id: j['id'] as int,
        nameArabic: j['nameArabic'] as String? ?? '',
        numberOfAyahs: j['numberOfAyahs'] as int,
        pageStart: j['pageStart'] as int,
        pageEnd: j['pageEnd'] as int,
        firstJuz: j['firstJuz'] as int,
        lastJuz: j['lastJuz'] as int,
      );
}

class QuranAyah {
  final int number;
  final String textArabic;
  final int juz;
  final int page;

  const QuranAyah({
    required this.number,
    required this.textArabic,
    required this.juz,
    required this.page,
  });

  factory QuranAyah.fromJson(Map<String, dynamic> j) => QuranAyah(
        number: j['id'] as int,
        textArabic: j['textArabic'] as String? ?? '',
        juz: j['juz'] as int,
        page: j['page'] as int,
      );
}

class QuranSurah {
  final int id;
  final String nameArabic;
  final int numberOfAyahs;
  final List<QuranAyah> ayahs;

  const QuranSurah({
    required this.id,
    required this.nameArabic,
    required this.numberOfAyahs,
    required this.ayahs,
  });

  factory QuranSurah.fromJson(Map<String, dynamic> j) {
    final ayahs = (j['ayahs'] as List)
        .map((a) => QuranAyah.fromJson(a as Map<String, dynamic>))
        .toList();
    return QuranSurah(
      id: j['id'] as int,
      nameArabic: j['nameArabic'] as String? ?? '',
      numberOfAyahs: j['numberOfAyahs'] as int,
      ayahs: ayahs,
    );
  }

  QuranAyah ayahAt(int number) => ayahs[number - 1];
}

/// شريحة ملونة للتجويد — إزاحات UTF-16 (تطابق مؤشرات نصوص Dart)
class TajweedSpan {
  final int start;
  final int end;
  final String rule;

  const TajweedSpan({
    required this.start,
    required this.end,
    required this.rule,
  });

  factory TajweedSpan.fromJson(Map<String, dynamic> j) => TajweedSpan(
        start: j['start'] as int,
        end: j['end'] as int,
        rule: j['rule'] as String? ?? '',
      );
}

/// جزء من القرآن (الثلاثون جزءًا)
class JuzInfo {
  final int id;
  final String nameArabic;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;

  const JuzInfo({
    required this.id,
    required this.nameArabic,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
  });

  factory JuzInfo.fromJson(Map<String, dynamic> j) => JuzInfo(
        id: j['id'] as int,
        nameArabic: j['nameArabic'] as String? ?? '',
        startSurah: j['startSurah'] as int,
        startAyah: j['startAyah'] as int,
        endSurah: j['endSurah'] as int,
        endAyah: j['endAyah'] as int,
      );
}

/// موضع آية داخل المصحف
class QuranPos {
  final int surah;
  final int ayah;

  const QuranPos(this.surah, this.ayah);

  String get key => '$surah:$ayah';

  @override
  bool operator ==(Object other) =>
      other is QuranPos && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  QuranPos next() {
    if (ayah >= 286 && surah == 2) {
      return QuranPos(surah + 1, 1);
    }
    // الحد الأقصى العام للآيات غير مطلوب هنا — الحركة تُقيَّد بالنطاق في الخدمة.
    return QuranPos(surah, ayah + 1);
  }
}