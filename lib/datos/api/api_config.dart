import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const _definedBaseUrl = String.fromEnvironment('BOOK_MANAGER_API_URL');

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
    if (kIsWeb) return '${Uri.base.scheme}://${Uri.base.host}:3000';
    return 'http://127.0.0.1:3000';
  }
}
