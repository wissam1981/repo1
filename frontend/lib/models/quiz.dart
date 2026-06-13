/// A single quiz question. The backend stores questions as free-form dicts whose
/// shape depends on [type] (mcq, tf, fill, open), so optional fields cover all
/// variants.
class QuizQuestion {
  final String type;
  final String question;
  final List<String> options; // mcq
  final int? correctIndex; // mcq
  final bool? correct; // tf
  final String? correctWord; // fill

  QuizQuestion({
    required this.type,
    required this.question,
    this.options = const [],
    this.correctIndex,
    this.correct,
    this.correctWord,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      type: json['type'] as String? ?? 'open',
      question: json['question'] as String? ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      correctIndex: json['correct_index'] as int?,
      correct: json['correct'] as bool?,
      correctWord: json['correct_word'] as String?,
    );
  }
}

class Quiz {
  final int id;
  final String quizType;
  final List<QuizQuestion> questions;

  Quiz({
    required this.id,
    required this.quizType,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as int,
      quizType: json['quiz_type'] as String? ?? '',
      questions: (json['questions'] as List?)
              ?.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class QuizAttempt {
  final int id;
  final double score;
  final String? feedback;
  final String? createdAt;

  QuizAttempt({
    required this.id,
    required this.score,
    this.feedback,
    this.createdAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'] as int,
      score: (json['score'] as num).toDouble(),
      feedback: json['feedback'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
