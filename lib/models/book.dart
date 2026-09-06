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
  final String downloadUrl; // رابط مباشر لملف PDF على GitHub
  final String volumeLabel; // تسمية الجزء داخل مجموعة (مثال: الجزء الأول)
  final List<Book> volumeChildren; // أجزاء الكتاب عند التجميع
  final List<Chapter> chapters;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.benefit,
    required this.intro,
    required this.reference,
    required this.assetFile,
    this.downloadUrl = '',
    this.volumeLabel = '',
    this.volumeChildren = const [],
    this.chapters = const [],
  });

  Book copyWithVolumeLabel(String label) {
    return Book(
      id: id,
      title: title,
      author: author,
      benefit: benefit,
      intro: intro,
      reference: reference,
      assetFile: assetFile,
      downloadUrl: downloadUrl,
      volumeLabel: label,
      volumeChildren: volumeChildren,
      chapters: chapters,
    );
  }

  factory Book.fromIndexJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      benefit: json['benefit'] ?? '',
      intro: json['intro'] ?? '',
      reference: json['reference'] ?? '',
      assetFile: json['file'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
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
        downloadUrl: downloadUrl,
        volumeLabel: volumeLabel,
        volumeChildren: volumeChildren,
        chapters: ch,
      );
}
