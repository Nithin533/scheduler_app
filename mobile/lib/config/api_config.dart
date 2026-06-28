import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  static const String _host = String.fromEnvironment('BASE_URL', defaultValue: '');
  static String get baseUrl {
    if (_host.isNotEmpty) {
      return 'http://$_host/api';
    }
    if (kIsWeb) return 'http://localhost:8000/api';
    // Android emulator uses 10.0.2.2 to reach host localhost
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  static const Duration timeout = Duration(seconds: 30);
}
