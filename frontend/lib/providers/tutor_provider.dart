import 'package:flutter/material.dart';
import '../models/tutor.dart';
import '../services/api_client.dart';

/// Owns the active tutor session (chat history + difficulty) and the list of
/// past sessions.
///
/// Backed by the backend tutor_router endpoints:
///   POST /tutor/sessions/{contract_id}        -> create session
///   POST /tutor/sessions/{session_id}/message -> send message, get reply
///   GET  /tutor/sessions/{session_id}         -> fetch a session
///   GET  /tutor/sessions                       -> list sessions
class TutorProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  TutorSession? _session;
  List<TutorSession> _sessions = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  TutorProvider(this._apiClient);

  TutorSession? get session => _session;
  List<TutorSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  int get difficulty => _session?.difficulty ?? 1;

  /// Creates a new tutor session for the given contract.
  Future<TutorSession> startSession(int contractId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.post('/tutor/sessions/$contractId', {});
      _session = TutorSession.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return _session!;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Ensures there is an active session for [contractId], creating one only
  /// if needed. Used by the tutor screen to never show a dead state.
  Future<TutorSession> ensureSession(int contractId) async {
    final existing = _session;
    if (existing != null && existing.contractId == contractId) return existing;
    return startSession(contractId);
  }

  /// Sends a message to the active session and stores the updated session
  /// (including the AI's reply and recalculated difficulty).
  Future<void> sendMessage(String message) async {
    final session = _session;
    if (session == null) {
      throw StateError('No active tutor session');
    }
    _isSending = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _apiClient.post('/tutor/sessions/${session.id}/message', {
        'session_id': session.id,
        'message': message,
      });
      _session = TutorSession.fromJson(response);
      _isSending = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Loads the user's past tutor sessions, most recent first.
  Future<void> loadSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.getList('/tutor/sessions');
      _sessions = response
          .map((s) => TutorSession.fromJson(s as Map<String, dynamic>))
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
