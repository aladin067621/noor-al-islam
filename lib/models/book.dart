import 'chapter.dart';

/// نموذج الكتاب في المكتبة الإسلامية
class Book {
  final String id;
  final String title;
  final String author;
  final String benefit; // الفائدة / نبذة
  final String intro; // مقدمة / نبذة عن المؤلف
  final String reference; // المصدر الرقمي
  final String assetFile; // ملف الفصول
  final List<Chapter> chapters;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.benefit,
    required this.intro,
    required this.reference,
    required this.assetFile,
    this.chapters = const [],
  });

  factory Book.fromIndexJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      benefit: json['benefit'] ?? '',
      intro: json['intro'] ?? '',
      reference: json['reference'] ?? '',
      assetFile: json['file'] ?? '',
    );
  }

  Book copyWithChapters(List<Chapter> ch) => Book(
        id: id,
        title: title,
        author: author,
        benefit: benefit,
        intro: intro,
        reference: reference,
        assetFile: assetFile,
        chapters: ch,
      );
}
