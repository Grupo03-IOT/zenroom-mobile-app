import 'package:flutter/foundation.dart';

class AppConfig {
  static const demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
  static const _configuredUrl = String.fromEnvironment('CLOUD_API_URL');

  static String get cloudApiUrl {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;
    if (kIsWeb) return 'http://127.0.0.1:8080';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8080'
        : 'http://127.0.0.1:8080';
  }
}
