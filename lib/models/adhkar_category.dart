import 'dhikr.dart';

/// فئة من فئات الأذكار (باب) — مثل باب من حصن المسلم أو الوابل الصيب
class AdhkarCategory {
  final String key;
  final String title;
  final List<Dhikr> items;
  final String book; // الكتاب الذي تنتمي إليه: 'حصن المسلم' أو 'الوابل الصيب'

  AdhkarCategory({
    required this.key,
    required this.title,
    required this.items,
    required this.book,
  });

  factory AdhkarCategory.fromJson(Map<String, dynamic> json, {String book = ''}) {
    return AdhkarCategory(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      items: (json['items'] as List)
          .map((e) => Dhikr.fromJson(e as Map<String, dynamic>, book))
          .toList(),
      book: book,
    );
  }

  /// مفتاح فريد يجمع الكتاب والفئة — يُستخدم للتثبيت والترتيب
  String get uniqueKey => '$book::$key';
}
