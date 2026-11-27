import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class CloudException implements Exception {
  final int statusCode;
  final String message;

  /// Codigo del catalogo de errores de Cloud (`{code, message, path, errors[]}`).
  final String? code;
  const CloudException(this.statusCode, this.message, {this.code});
  @override
  String toString() => message;
}

const accountDisabledCode = 'IAM_ACCOUNT_DISABLED';
const invalidCredentialsCode = 'IAM_INVALID_CREDENTIALS';
const invalidCredentialsMessage = 'Correo o contraseña incorrectos.';
const accountDisabledMessage =
    'Esta cuenta está desactivada. Contacta a un administrador.';

/// Mensaje de acceso para un error del login: credenciales (400/401) o cuenta
/// desactivada. Devuelve null si el error no es de ese tipo.
String? loginErrorMessage(CloudException error) {
  if (error.code == accountDisabledCode) return accountDisabledMessage;
  if (error.code == invalidCredentialsCode ||
      error.statusCode == 400 ||
      error.statusCode == 401) {
    return invalidCredentialsMessage;
  }
  return null;
}

class CloudClient {
  CloudClient({http.Client? httpClient, this.onAccountDisabled})
    : _http = httpClient ?? http.Client();
  final http.Client _http;

  /// Se invoca cuando una llamada autenticada responde 401 IAM_ACCOUNT_DISABLED.
  /// El login no envia token, por lo que su 401 nunca dispara este callback.
  void Function()? onAccountDisabled;

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
      String? code;
      try {
        final data = jsonDecode(response.body);
        if (data is Map) {
          code = data['code'] as String?;
          message =
              '${data['message'] ?? data['detail'] ?? data['error'] ?? message}';
        }
      } catch (_) {}
      if (response.statusCode == 401 &&
          code == accountDisabledCode &&
          token != null &&
          token.isNotEmpty) {
        onAccountDisabled?.call();
      }
      throw CloudException(response.statusCode, message, code: code);
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
