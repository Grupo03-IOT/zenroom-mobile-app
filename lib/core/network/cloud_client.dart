import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class CloudException implements Exception {
  final int statusCode;
  final String message;
  const CloudException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class CloudClient {
  CloudClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();
  final http.Client _http;

  Future<dynamic> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final base = AppConfig.cloudApiUrl.replaceAll(RegExp(r'/$'), '');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final payload = body == null ? null : jsonEncode(_mapKeys(body, _toSnake));
    late http.Response response;
    try {
      response = await _http
          .send(
            http.Request(method, Uri.parse('$base$path'))
              ..headers.addAll(headers)
              ..body = payload ?? '',
          )
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      throw const CloudException(0, 'No se pudo conectar con Cloud API.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Error ${response.statusCode} al consultar Cloud API.';
      try {
        final data = jsonDecode(response.body);
        if (data is Map) {
          message =
              '${data['message'] ?? data['detail'] ?? data['error'] ?? message}';
        }
      } catch (_) {}
      throw CloudException(response.statusCode, message);
    }
    if (response.body.trim().isEmpty) return null;
    return _mapKeys(jsonDecode(response.body), _toCamel);
  }

  static dynamic _mapKeys(dynamic value, String Function(String) transform) {
    if (value is List)
      return value.map((item) => _mapKeys(item, transform)).toList();
    if (value is Map) {
      return value.map(
        (key, item) =>
            MapEntry(transform(key.toString()), _mapKeys(item, transform)),
      );
    }
    return value;
  }

  static String _toCamel(String key) => key.replaceAllMapped(
    RegExp(r'_([a-z])'),
    (m) => m.group(1)!.toUpperCase(),
  );
  static String _toSnake(String key) => key.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '_${m.group(0)!.toLowerCase()}',
  );
}
