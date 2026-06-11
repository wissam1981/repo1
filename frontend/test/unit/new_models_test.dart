import 'package:contract_english_trainer/models/quiz.dart';
import 'package:contract_english_trainer/models/tutor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quiz models', () {
    test('Quiz.fromJson parses mcq questions', () {
      final json = {
        'id': 1,
        'quiz_type': 'mcq',
        'questions': [
          {
            'type': 'mcq',
            'question': 'What does "indemnify" mean?',
            'options': ['Compensate', 'Ignore', 'Cancel'],
            'correct_index': 0,
          }
        ],
      };
      final quiz = Quiz.fromJson(json);
      expect(quiz.id, 1);
      expect(quiz.quizType, 'mcq');
      expect(quiz.questions.length, 1);
      expect(quiz.questions[0].type, 'mcq');
      expect(quiz.questions[0].options.length, 3);
      expect(quiz.questions[0].correctIndex, 0);
    });

    test('QuizQuestion.fromJson parses tf and fill variants', () {
      final tf = QuizQuestion.fromJson({
        'type': 'tf',
        'question': 'This clause is binding.',
        'correct': true,
      });
      expect(tf.type, 'tf');
      expect(tf.correct, true);

      final fill = QuizQuestion.fromJson({
        'type': 'fill',
        'question': 'The ____ shall apply.',
        'correct_word': 'law',
      });
      expect(fill.correctWord, 'law');
    });

    test('QuizAttempt.fromJson parses score and feedback', () {
      final attempt = QuizAttempt.fromJson({
        'id': 7,
        'score': 0.8,
        'feedback': 'Good work',
        'created_at': '2026-06-08T10:00:00',
      });
      expect(attempt.id, 7);
      expect(attempt.score, 0.8);
      expect(attempt.feedback, 'Good work');
    });
  });

  group('Tutor models', () {
    test('TutorSession.fromJson parses messages and difficulty', () {
      final json = {
        'id': 3,
        'user_id': 1,
        'contract_id': 2,
        'difficulty': 4,
        'created_at': '2026-06-08T10:00:00',
        'messages': [
          {'role': 'user', 'content': 'Hi'},
          {'role': 'assistant', 'content': 'Hello! Let us learn.'},
        ],
      };
      final session = TutorSession.fromJson(json);
      expect(session.id, 3);
      expect(session.contractId, 2);
      expect(session.difficulty, 4);
      expect(session.messages.length, 2);
      expect(session.messages[0].role, 'user');
      expect(session.messages[1].content, 'Hello! Let us learn.');
    });

    test('TutorSession.fromJson handles missing messages gracefully', () {
      final session = TutorSession.fromJson({
        'id': 1,
        'user_id': 1,
        'contract_id': 1,
        'difficulty': 1,
      });
      expect(session.messages, isEmpty);
      expect(session.difficulty, 1);
    });
  });
}
