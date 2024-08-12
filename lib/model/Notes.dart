class Note {
  final String title;

  Note({
    required this.title,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      title: map['title'] as String,
    );
  }
}
