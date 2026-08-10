/// نموذج الذكر
class Dhikr {
  final String id;
  final String text; // نص الذكر كاملاً
  final int repetitions; // عدد مرات التكرار
  final String source; // المصدر: "رواه البخاري"...
  final String category; // الفئة: صباح / مساء / نوم / سفر...
  final String? virtue; // فضل الذكر (اختياري)
  bool isFavorite;

  Dhikr({
    required this.id,
    required this.text,
    required this.repetitions,
    required this.source,
    required this.category,
    this.virtue,
    this.isFavorite = false,
  });

  factory Dhikr.fromJson(Map<String, dynamic> json, String category) {
    return Dhikr(
      id: json['id']?.toString() ?? '${category}_${json['text'].hashCode}',
      text: json['text'] ?? '',
      repetitions: json['repetitions'] ?? 1,
      source: json['source'] ?? '',
      category: json['category'] ?? category,
      virtue: json['virtue'],
    );
  }

  /// مفتاح فريد للمفضلة
  String get favoriteKey => 'dhikr:$id';

  String shareText() {
    final buffer = StringBuffer()
      ..writeln(text)
      ..writeln()
      ..writeln('التكرار: $repetitions');
    if (source.isNotEmpty) buffer.writeln('المصدر: $source');
    return buffer.toString().trim();
  }
}
