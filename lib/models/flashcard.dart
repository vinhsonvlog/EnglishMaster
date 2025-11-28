class Flashcard {
  final String id;
  final String term;       // Tương ứng với mặt trước (front)
  final String definition; // Tương ứng với mặt sau (back)
  final String? example;
  final String? pronunciation;
  final String? imageUrl;

  Flashcard({
    required this.id,
    required this.term,
    required this.definition,
    this.example,
    this.pronunciation,
    this.imageUrl,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['_id'] ?? '',

      // QUAN TRỌNG: Backend trả về 'front', ta map vào 'term'
      term: json['front'] ?? json['term'] ?? 'Không có từ',

      // QUAN TRỌNG: Backend trả về 'back', ta map vào 'definition'
      definition: json['back'] ?? json['definition'] ?? 'Không có nghĩa',

      example: json['example'],
      pronunciation: json['pronunciation'],
      imageUrl: json['imageUrl'],
    );
  }
}