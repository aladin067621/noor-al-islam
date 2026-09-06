/// نموذج الذكر
class Dhikr {
  final String id;
  final String text; // نص الذكر كاملاً
  final int repetitions; // عدد مرات التكرار
  final String source; // المصدر: "رواه البخاري"...
  final String category; // الفئة: صباح / مساء / نوم / سفر...
  final String? virtue; // فضل الذكر (اختياري)
  final String? sourceBook; // الكتاب الذي نُقل منه الذكر
  final String? sourceChapter; // الباب الذي ورد فيه الذكر
  final String? narrator; // الراوي إن ورد في المصدر
  final String? hadithReference; // اسم المصدر الحديثي ورقم الحديث
  final String? grading; // درجة الحديث إن وردت
  final int? sourcePage; // صفحة الذكر في الكتاب
  final String sourceKey; // هوية الملف/المصدر: morning/evening/.../hisn/wabil
  final String? categoryKey; // مفتاح الفصل للكتب متعددة الأبواب (حصن/وابل)
  bool isFavorite;

  Dhikr({
    required this.id,
    required this.text,
    required this.repetitions,
    required this.source,
    required this.category,
    this.virtue,
    this.sourceBook,
    this.sourceChapter,
    this.narrator,
    this.hadithReference,
    this.grading,
    this.sourcePage,
    this.sourceKey = '',
    this.categoryKey,
    this.isFavorite = false,
  });

  factory Dhikr.fromJson(Map<String, dynamic> json, String category,
      {String sourceKey = '', String? categoryKey}) {
    return Dhikr(
      id: json['id']?.toString() ?? '${category}_${json['text'].hashCode}',
      text: json['text'] ?? '',
      repetitions: json['repetitions'] ?? 1,
      source: json['source'] ?? '',
      category: json['category'] ?? category,
      virtue: json['virtue'],
      sourceBook: json['sourceBook'],
      sourceChapter: json['sourceChapter'],
      narrator: json['narrator'],
      hadithReference: json['hadithReference'],
      grading: json['grading'],
      sourcePage: json['sourcePage'] is int
          ? json['sourcePage'] as int
          : int.tryParse('${json['sourcePage'] ?? ''}'),
      sourceKey: sourceKey,
      categoryKey: categoryKey,
    );
  }

  /// مفتاح فريد للمفضلة
  String get favoriteKey => 'dhikr:$id';

  /// مفتاح مرجعي فريد يتيح ربط الذكر نفسه من أي ملف:
  /// ملفات الأقسام الأساسية: morning::id ... وكتب الأبواب: hisn::chapter::id
  String get refKey =>
      (categoryKey == null || categoryKey!.isEmpty) ? '$sourceKey::$id' : '$sourceKey::$categoryKey::$id';

  String shareText() {
    final buffer = StringBuffer()
      ..writeln(text)
      ..writeln()
      ..writeln('التكرار: $repetitions');
    if (source.isNotEmpty) buffer.writeln('المصدر: $source');
    return buffer.toString().trim();
  }
}
