import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Buyer knobs: change app name, colors (see [AppTheme]), and API URL here.
class AppConfig {
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Auth Starter',
  );

  /// Google OAuth Web Client ID (also used as serverClientId on Android).
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  /// API root. Override: `flutter run --dart-define=API_BASE=http://192.168.x.x:8000`
  static String get apiBase {
    const fromEnv = String.fromEnvironment('API_BASE');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // The emulator is its own device: 10.0.2.2 means "the host computer".
      // On a real phone, pass your computer's LAN IP via --dart-define=API_BASE.
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
