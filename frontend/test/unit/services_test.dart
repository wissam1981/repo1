import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contract_english_trainer/services/auth_service.dart';

/// In-memory implementation of FlutterSecureStorage for unit testing.
/// Overrides read/write/delete so no platform channel is invoked.
class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.remove(key);
}

void main() {
  group('AuthService', () {
    test('saveToken and getStoredToken round-trip correctly', () async {
      final storage = MockSecureStorage();
      final authService = AuthService(storage: storage);

      await authService.saveToken('my-jwt-token');
      final token = await authService.getStoredToken();

      expect(token, equals('my-jwt-token'));
    });

    test('logout clears the stored token', () async {
      final storage = MockSecureStorage();
      final authService = AuthService(storage: storage);

      await authService.saveToken('my-jwt-token');
      await authService.logout();
      final token = await authService.getStoredToken();

      expect(token, isNull);
    });
  });
}
