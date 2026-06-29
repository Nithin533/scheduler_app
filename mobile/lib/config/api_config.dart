import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Default host for local dev (emulator).
  /// Override BASE_URL with: --dart-define=BASE_URL=host:port
  /// Override PROTOCOL with: --dart-define=PROTOCOL=https  (for Railway/cloud)
  static const String _defaultHost = '10.0.2.2:8000';
  static const String _defaultProtocol = 'http';

  static const String _host = String.fromEnvironment('BASE_URL', defaultValue: _defaultHost);
  static const String _protocol = String.fromEnvironment('PROTOCOL', defaultValue: _defaultProtocol);

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    return '$_protocol://$_host/api';
  }

  static const Duration timeout = Duration(seconds: 30);
}
