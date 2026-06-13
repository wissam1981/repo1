class Env {
  /// Backend API base URL.
  ///
  /// Overridable at build time, e.g. for a physical phone that must reach the
  /// dev Mac over the LAN:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.100.31:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Google OAuth Client ID (update for production)
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID_IOS.apps.googleusercontent.com';

  /// Apple Team ID (for Sign in with Apple)
  static const String appleTeamId = 'YOUR_APPLE_TEAM_ID';
}
