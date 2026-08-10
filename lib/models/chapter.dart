/// نموذج فصل من فصول كتاب
class Chapter {
  final String id;
  final String title;
  final String content; // النص كاملاً
  final String bookId;
  final String bookTitle;

  Chapter({
    required this.id,
    required this.title,
    required this.content,
    required this.bookId,
    required this.bookTitle,
  });

  factory Chapter.fromJson(Map<String, dynamic> json, String bookId, String bookTitle) {
    return Chapter(
      id: json['id']?.toString() ?? '${bookId}_${json['title'].hashCode}',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      bookId: bookId,
      bookTitle: bookTitle,
    );
  }

  String get favoriteKey => 'chapter:$bookId:$id';

  String shareText() => '$bookTitle — $title\n\n$content';
}
