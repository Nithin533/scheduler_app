import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Change this to your machine's LAN IP when testing on a real device.
  /// Example: '192.168.1.100:8000'
  /// For Android emulator, 10.0.2.2 maps to host machine's localhost.
  /// Can be overridden at build time with: --dart-define=BASE_URL=host:port
  static const String _defaultHost = '10.0.2.2:8000';

  static const String _host = String.fromEnvironment('BASE_URL', defaultValue: _defaultHost);

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    return 'http://$_host/api';
  }

  static const Duration timeout = Duration(seconds: 30);
}
