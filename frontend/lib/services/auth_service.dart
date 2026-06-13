import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  final FlutterSecureStorage storage;
  late final ApiClient apiClient;

  AuthService({FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage() {
    apiClient = ApiClient(getToken: () => getStoredToken());
  }

  Future<String?> getStoredToken() async {
    return await storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await storage.write(key: _tokenKey, value: token);
  }

  Future<String> loginWithGoogle(String idToken) async {
    final response = await apiClient.post('/auth/login', {
      'provider': 'google',
      'id_token': idToken,
    });
    final token = response['access_token'] as String;
    await saveToken(token);
    return token;
  }

  Future<String> loginWithApple(String idToken) async {
    final response = await apiClient.post('/auth/login', {
      'provider': 'apple',
      'id_token': idToken,
    });
    final token = response['access_token'] as String;
    await saveToken(token);
    return token;
  }

  Future<String> loginAsGuest() async {
    final response = await apiClient.post('/auth/guest', {});
    final token = response['access_token'] as String;
    await saveToken(token);
    return token;
  }

  Future<void> logout() async {
    await storage.delete(key: _tokenKey);
  }

  /// Returns true if a token is currently persisted.
  /// Note: this is async-safe; use [getStoredToken] for the actual value.
  Future<bool> get isLoggedIn async => (await getStoredToken()) != null;
}
