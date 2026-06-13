import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/api_client.dart';

/// Owns the currently displayed quiz, the latest submission result, and the
/// user's quiz attempt history.
///
/// Backed by the backend quizzes_router endpoints:
///   POST /quizzes/generate
///   POST /quizzes/submit
///   GET  /quizzes/history
class QuizzesProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  Quiz? _currentQuiz;
  QuizAttempt? _lastResult;
  List<QuizAttempt> _history = [];
  bool _isLoading = false;
  String? _error;

  QuizzesProvider(this._apiClient);

  Quiz? get currentQuiz => _currentQuiz;
  QuizAttempt? get lastResult => _lastResult;
  List<QuizAttempt> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Generates a quiz from a clause or contract the user owns.
  Future<Quiz> generateQuiz({
    int? clauseId,
    int? contractId,
    String quizType = 'mcq',
    int count = 3,
  }) async {
    _isLoading = true;
    _error = null;
    _lastResult = null;
    notifyListeners();
    try {
      final response = await _apiClient.post('/quizzes/generate', {
        if (clauseId != null) 'clause_id': clauseId,
        if (contractId != null) 'contract_id': contractId,
        'quiz_type': quizType,
        'count': count,
      });
      _currentQuiz = Quiz.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return _currentQuiz!;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Submits answers for the current quiz and stores the graded result.
  Future<QuizAttempt> submitQuiz(int quizId, List<dynamic> answers) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.post('/quizzes/submit', {
        'quiz_id': quizId,
        'answers': answers,
      });
      _lastResult = QuizAttempt.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return _lastResult!;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Loads the user's quiz attempts, most recent first.
  Future<void> loadHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.getList('/quizzes/history');
      _history = response
          .map((a) => QuizAttempt.fromJson(a as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
