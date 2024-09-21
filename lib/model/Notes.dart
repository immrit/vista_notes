import 'dart:convert';

class Note {
  final dynamic id;
  final String title;
  final String content;

  Note({
    required this.id,
    required this.title,
    required this.content,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
    );
  }

  Note copyWith({
    String? title,
    String? content,
  }) {
    return Note(
      title: title ?? this.title,
      content: content ?? this.content,
      id: id ?? id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
    };
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));

  @override
  String toString() => 'Note(title: $title, content: $content)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Note && other.title == title && other.content == content;
  }

  @override
  int get hashCode => title.hashCode ^ content.hashCode;
}
