import 'package:flutter/material.dart';
import '../models/vocabulary.dart';
import '../services/api_client.dart';

/// Owns the user's due vocabulary words and mediates save / review actions.
///
/// Screens consume this provider via [Consumer]; no direct HTTP calls are made
/// from the UI layer. Backed by the backend vocabulary_router endpoints:
///   GET  /vocabulary/due
///   POST /vocabulary/words
///   PUT  /vocabulary/reviews/{id}
class VocabularyProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<Word> _dueWords = [];
  bool _isLoading = false;
  String? _error;

  VocabularyProvider(this._apiClient);

  List<Word> get dueWords => List.unmodifiable(_dueWords);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches all words whose next review is due now or in the past.
  Future<void> loadDueWords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.getList('/vocabulary/due');
      _dueWords = response
          .map((w) => Word.fromJson(w as Map<String, dynamic>))
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

  /// Saves a new vocabulary word and adds it to the local list.
  Future<Word> saveWord(
    String term,
    String meaning,
    String example, {
    int? clauseId,
  }) async {
    _error = null;
    try {
      final response = await _apiClient.post('/vocabulary/words', {
        'term': term,
        'meaning': meaning,
        'example': example,
        if (clauseId != null) 'clause_id': clauseId,
      });
      final word = Word.fromJson(response);
      _dueWords = [..._dueWords, word];
      notifyListeners();
      return word;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Looks up a tapped word with AI and saves it to the vocabulary in one
  /// call (backend POST /vocabulary/tap). Returns the saved word.
  Future<Word> tapWord(String term, {int? clauseId}) async {
    final response = await _apiClient.post('/vocabulary/tap', {
      'term': term,
      if (clauseId != null) 'clause_id': clauseId,
    });
    return Word(
      id: response['word_id'] as int,
      term: response['term'] as String,
      meaning: response['meaning'] as String,
      example: response['example'] as String? ?? '',
      meaningEn: response['meaning_en'] as String?,
      meaningAr: response['meaning_ar'] as String?,
    );
  }

  /// URL streaming natural AI pronunciation of [text] (backend OpenAI TTS).
  /// The JWT rides in the query string because audio players cannot send
  /// Authorization headers.
  Future<String> pronounceUrl(String text) async {
    final token = await _apiClient.getToken() ?? '';
    final q = Uri.encodeQueryComponent(text);
    final t = Uri.encodeQueryComponent(token);
    return '${_apiClient.baseUrl}/vocabulary/pronounce?text=$q&token=$t';
  }

  /// Records the outcome of a review (SM-2 quality 0–5) and removes the word
  /// from the due list on success.
  Future<void> recordReview(int reviewId, int quality, {int? wordId}) async {
    _error = null;
    try {
      await _apiClient.put('/vocabulary/reviews/$reviewId', {
        'review_id': reviewId,
        'quality': quality,
      });
      if (wordId != null) {
        _dueWords = _dueWords.where((w) => w.id != wordId).toList();
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
