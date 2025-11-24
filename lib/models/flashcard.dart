class Flashcard {
  final String id;
  final String term;       // Từ vựng (Ví dụ: Apple)
  final String definition; // Định nghĩa (Ví dụ: Quả táo)
  final String? example;   // Ví dụ câu
  final String? audioUrl;  // Link phát âm (nếu có)

  Flashcard({
    required this.id,
    required this.term,
    required this.definition,
    this.example,
    this.audioUrl,
  });

  // Hàm chuyển từ JSON (Server trả về) sang Object Dart
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['_id'] ?? '',
      term: json['term'] ?? '',
      definition: json['definition'] ?? '',
      example: json['example'],
      audioUrl: json['audioUrl'],
    );
  }
}