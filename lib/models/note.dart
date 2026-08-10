/// نموذج الملاحظة
class Note {
  final int? id;
  final String title;
  final String content;
  final int createdAt; // ميلي ثانية منذ epoch
  final int updatedAt;
  final String? linkedRef; // ربط بذكر أو فصل كتاب (مفتاح اختياري)
  final String? linkedLabel; // وصف العنصر المرتبط

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.linkedRef,
    this.linkedLabel,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'content': content,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'linked_ref': linkedRef,
        'linked_label': linkedLabel,
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] as int?,
        title: map['title'] ?? '',
        content: map['content'] ?? '',
        createdAt: map['created_at'] ?? 0,
        updatedAt: map['updated_at'] ?? 0,
        linkedRef: map['linked_ref'],
        linkedLabel: map['linked_label'],
      );
}
