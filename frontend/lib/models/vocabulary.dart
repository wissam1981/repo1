class Word {
  final int id;
  final String term;
  final String meaning;
  final String example;
  final int? clauseId;
  final String? meaningEn;
  final String? meaningAr;

  Word({
    required this.id,
    required this.term,
    required this.meaning,
    required this.example,
    this.clauseId,
    this.meaningEn,
    this.meaningAr,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      term: json['term'],
      meaning: json['meaning'],
      example: json['example'],
      clauseId: json['clause_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'term': term,
    'meaning': meaning,
    'example': example,
    'clause_id': clauseId,
  };
}

class Review {
  final int id;
  final int wordId;
  final String dueDateStr;
  final int repetitions;
  final double ease;

  Review({
    required this.id,
    required this.wordId,
    required this.dueDateStr,
    required this.repetitions,
    required this.ease,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      wordId: json['word_id'],
      dueDateStr: json['due_date'],
      repetitions: json['repetitions'],
      ease: (json['ease'] as num).toDouble(),
    );
  }
}
