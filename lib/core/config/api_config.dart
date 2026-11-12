import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String _customBaseUrl = '';
  static void setBaseUrl(String url) => _customBaseUrl = url.trim();

  /// macOS e iOS consumen el backend en 127.0.0.1.
  /// Android Emulator usa 10.0.2.2 para comunicarse con el host Mac.
  /// Android físico por USB usa 127.0.0.1 (ejecutando `adb reverse tcp:8000 tcp:8000`).
  /// Android físico por Wi-Fi usa la IP local de la red de la Mac.
  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://127.0.0.1:8000';
    }
    // Android por defecto: 10.0.2.2 para emuladores
    return 'http://10.0.2.2:8000';
  }
}
