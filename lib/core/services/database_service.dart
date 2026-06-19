import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../config/database_config.dart';
import '../../data/models/database_response.dart';

class DatabaseService {
  // ── Token en memoria ─────────────────────────────────────────
  static String? _authToken;

  static const _kTokenKey  = 'accessToken';
  static const _kUserIdKey = 'userId';

  /// Llama esto en main() antes de runApp() para restaurar sesión
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_kTokenKey);
    if (_authToken != null) {
      print('[DatabaseService] Token restaurado desde SharedPreferences');
    }
  }

  // ── URL helpers ──────────────────────────────────────────────
  static String get _baseUrl    => DatabaseConfig.baseUrl;
  static String get _rawBaseUrl => DatabaseConfig.rawBaseUrl;

  // ── Gestión de token ─────────────────────────────────────────
  static Future<void> setAuthToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_kTokenKey, token);
    } else {
      await prefs.remove(_kTokenKey);
    }
    print('[DatabaseService] Token ${token != null ? "guardado" : "eliminado"}');
  }

  static Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserIdKey);
    print('[DatabaseService] Sesión limpiada');
  }

  static bool hasAuthToken() => _authToken != null && _authToken!.isNotEmpty;
  static String? getAuthToken() => _authToken;

  // ── Headers ──────────────────────────────────────────────────
  static Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> get _authHeaders => {
    ..._baseHeaders,
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ── Health check (usa rawBaseUrl sin /api/v1) ─────────────────
  static Future<DatabaseResponse<Map<String, dynamic>>> checkConnection() async {
    try {
      final url = '$_rawBaseUrl/health';
      print('[DatabaseService] Verificando conexión → $url');

      final response = await http
          .get(Uri.parse(url), headers: _baseHeaders)
          .timeout(const Duration(milliseconds: DatabaseConfig.connectionTimeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DatabaseResponse.success({
          'connected': true,
          'server': _baseUrl,
          'serverResponse': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      return DatabaseResponse.error(
          'Servidor respondió con código ${response.statusCode}');
    } on SocketException {
      return DatabaseResponse.error(
          'Sin conexión de red. Verifica que el servidor esté corriendo.');
    } on TimeoutException {
      return DatabaseResponse.error(
          'Timeout: el servidor no responde en $_rawBaseUrl');
    } catch (e) {
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // ── GET ───────────────────────────────────────────────────────
  static Future<DatabaseResponse<T>> get<T>(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      print('[DatabaseService] GET $url');
      final response = await http
          .get(Uri.parse(url),
              headers: requiresAuth ? _authHeaders : _baseHeaders)
          .timeout(const Duration(milliseconds: DatabaseConfig.connectionTimeout));
      return _handleResponse<T>(response, 'GET', endpoint);
    } catch (e) {
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // ── POST ──────────────────────────────────────────────────────
  static Future<DatabaseResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      print('[DatabaseService] POST $url');
      final response = await http
          .post(Uri.parse(url),
              headers: requiresAuth ? _authHeaders : _baseHeaders,
              body: json.encode(data))
          .timeout(const Duration(milliseconds: DatabaseConfig.connectionTimeout));
      return _handleResponse<T>(response, 'POST', endpoint);
    } catch (e) {
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // ── PUT ───────────────────────────────────────────────────────
  static Future<DatabaseResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      print('[DatabaseService] PUT $url');
      final response = await http
          .put(Uri.parse(url),
              headers: requiresAuth ? _authHeaders : _baseHeaders,
              body: json.encode(data))
          .timeout(const Duration(milliseconds: DatabaseConfig.connectionTimeout));
      return _handleResponse<T>(response, 'PUT', endpoint);
    } catch (e) {
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // ── PATCH ─────────────────────────────────────────────────────
  static Future<DatabaseResponse<T>> patch<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      print('[DatabaseService] PATCH $url');
      final response = await http
          .patch(Uri.parse(url),
              headers: requiresAuth ? _authHeaders : _baseHeaders,
              body: json.encode(data))
          .timeout(const Duration(milliseconds: DatabaseConfig.connectionTimeout));
      return _handleResponse<T>(response, 'PATCH', endpoint);
    } catch (e) {
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // ── DELETE ────────────────────────────────────────────────────
  static Future<DatabaseResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      print('[DatabaseService] DELETE $url');
      final response = await http
          .delete(Uri.parse(url),
              headers: requiresAuth ? _authHeaders : _baseHeaders)
          .timeout(const Duration(milliseconds: DatabaseConfig.connectionTimeout));
      return _handleResponse<T>(response, 'DELETE', endpoint);
    } catch (e) {
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // ── POST con archivo (multipart) ─────────────────────────────
  static Future<DatabaseResponse<T>> postWithFile<T>(
    String endpoint,
    Map<String, String> fields,
    File? file,
    String fileFieldName, {
    bool requiresAuth = false,
  }) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));
      if (requiresAuth && _authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.fields.addAll(fields);
      if (file != null) {
        request.files
            .add(await http.MultipartFile.fromPath(fileFieldName, file.path));
      }
      final streamedResponse = await request
          .send()
          .timeout(const Duration(milliseconds: DatabaseConfig.connectionTimeout));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse<T>(response, 'POST (multipart)', endpoint);
    } catch (e) {
      return DatabaseResponse.error('Error al subir archivo: $e');
    }
  }

  // ── PUT con archivo (multipart) ──────────────────────────────
  static Future<DatabaseResponse<T>> putWithFile<T>(
    String endpoint,
    Map<String, String> fields,
    File? file,
    String fileFieldName, {
    bool requiresAuth = false,
  }) async {
    try {
      final request =
          http.MultipartRequest('PUT', Uri.parse('$_baseUrl$endpoint'));
      if (requiresAuth && _authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.fields.addAll(fields);
      if (file != null) {
        request.files
            .add(await http.MultipartFile.fromPath(fileFieldName, file.path));
      }
      final streamedResponse = await request
          .send()
          .timeout(const Duration(milliseconds: DatabaseConfig.connectionTimeout));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse<T>(response, 'PUT (multipart)', endpoint);
    } catch (e) {
      return DatabaseResponse.error('Error al actualizar con archivo: $e');
    }
  }

  // ── POST multipart genérico ───────────────────────────────────
  static Future<DatabaseResponse<T>> postMultipart<T>(
    String endpoint,
    Map<String, String> fields, {
    File? file,
    String? fileFieldName,
  }) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.fields.addAll(fields);
      if (file != null && fileFieldName != null) {
        request.files
            .add(await http.MultipartFile.fromPath(fileFieldName, file.path));
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse<T>(response, 'POST (multipart)', endpoint);
    } catch (e) {
      return DatabaseResponse.failure(error: 'Error de conexión: $e');
    }
  }

  // ── Helpers de multipart ─────────────────────────────────────
  static http.MultipartRequest buildMultipartRequest(String method, Uri uri) {
    final request = http.MultipartRequest(method, uri);
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }
    return request;
  }

  static Future<http.MultipartFile> createMultipartFile(
      File file, String fieldName) async {
    final ext = file.path.toLowerCase();
    MediaType contentType;
    if (ext.endsWith('.png')) {
      contentType = MediaType('image', 'png');
    } else {
      contentType = MediaType('image', 'jpeg');
    }
    return await http.MultipartFile.fromPath(file.path, fieldName,
        contentType: contentType);
  }

  static Future<http.MultipartFile> createMultipartFileFromXFile(
      XFile file, String fieldName) async {
    final ext = file.name.toLowerCase();
    MediaType contentType;
    if (ext.endsWith('.png')) {
      contentType = MediaType('image', 'png');
    } else {
      contentType = MediaType('image', 'jpeg');
    }
    final bytes = await file.readAsBytes();
    return http.MultipartFile.fromBytes(fieldName, bytes,
        filename: file.name, contentType: contentType);
  }

  static Future<DatabaseResponse<Map<String, dynamic>>> sendMultipartRequest(
      http.MultipartRequest request) async {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse<Map<String, dynamic>>(
        response, request.method, request.url.path);
  }

  // ── Manejador centralizado de respuestas ─────────────────────
  static DatabaseResponse<T> _handleResponse<T>(
      http.Response response, String method, String endpoint) {
    final statusCode = response.statusCode;
    final bodyPreview = response.body.length > 300
        ? '${response.body.substring(0, 300)}...'
        : response.body;
    print('[DatabaseService] $method $endpoint → $statusCode | $bodyPreview');

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final data = json.decode(response.body);
        return DatabaseResponse.success(data, statusCode: statusCode);
      } catch (_) {
        return DatabaseResponse.success(response.body as T,
            statusCode: statusCode);
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        String msg = 'Error del servidor';
        if (errorData is Map<String, dynamic>) {
          final err = errorData['error'];
          if (err is Map && err['message'] != null) {
            msg = err['message'];
          } else if (err is String) {
            msg = err;
          } else if (errorData['message'] != null) {
            msg = errorData['message'];
          }
        }
        return DatabaseResponse.error(msg, statusCode);
      } catch (_) {
        return DatabaseResponse.error(
            'Error HTTP $statusCode: ${response.body}', statusCode);
      }
    }
  }

  // ── Utilidades ────────────────────────────────────────────────
  static String get baseUrl => _baseUrl;

  static Future<bool> isEndpointAvailable(String endpoint) async {
    try {
      final response = await http
          .head(Uri.parse('$_baseUrl$endpoint'), headers: _authHeaders)
          .timeout(const Duration(seconds: 5));
      return response.statusCode != 404;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> getDebugInfo() => {
        'baseUrl': _baseUrl,
        'hasToken': hasAuthToken(),
        'tokenPreview':
            _authToken != null ? '${_authToken!.substring(0, 20)}...' : null,
        'connectionTimeout': DatabaseConfig.connectionTimeout,
        'timestamp': DateTime.now().toIso8601String(),
      };
}
