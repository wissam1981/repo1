import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// ChangeNotifier that owns the current user session (token + user data).
///
/// Screens depend only on this provider — no direct service calls from UI.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _user;
  String? _token;
  bool _isLoading = false;

  AuthProvider(this._authService);

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  /// Called at app start-up to restore a persisted session.
  Future<void> initialize() async {
    _token = await _authService.getStoredToken();
    notifyListeners();
  }

  /// Returns true if the stored session still works against the backend.
  /// Clears the session on failure (e.g. the user was deleted server-side),
  /// so the app can route back to login instead of showing dead screens.
  Future<bool> validateSession() async {
    if (_token == null) return false;
    try {
      await _authService.apiClient.getList('/contracts');
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  /// Signs in with a Google ID token obtained from the Google Sign-In SDK.
  /// TODO: wire up google_sign_in package in a later plan.
  Future<void> loginWithGoogle(String idToken) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.loginWithGoogle(idToken);
      _token = await _authService.getStoredToken();
      // _user = ... fetch from /auth/me after token is set
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Signs in with an Apple ID token obtained from Sign in with Apple SDK.
  /// TODO: wire up sign_in_with_apple package in a later plan.
  Future<void> loginWithApple(String idToken) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.loginWithApple(idToken);
      _token = await _authService.getStoredToken();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Signs in as a guest user.
  Future<void> loginAsGuest() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.loginAsGuest();
      _token = await _authService.getStoredToken();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Clears the session both in memory and in secure storage.
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _token = null;
    notifyListeners();
  }
}
