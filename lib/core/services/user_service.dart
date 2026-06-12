import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import '../config/database_config.dart';
import '../constants/database_endpoints.dart';
import 'database_service.dart';
import '../../data/models/database_response.dart';
import '../../data/models/user_response.dart';

class UserService {
  // ── Obtener usuario por ID ─────────────────────────────────────
  static Future<UserResponse> getUserById({
    required String token,
    required String userId,
    int maxRetries = 2,             // mantenido por compatibilidad
    Duration timeout = const Duration(seconds: 10), // mantenido por compatibilidad
  }) async {
    DatabaseService.setAuthToken(token);
    try {
      final response = await DatabaseService.get<dynamic>(
        DatabaseEndpoints.usuarioById(userId),
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        final map = _toMap(response.data);
        if (map != null) return UserResponse.success(UserData.fromJson(map));
        return UserResponse.error('Estructura de respuesta inválida');
      }
      return UserResponse.error(_errorMsg(response));
    } catch (e) {
      return UserResponse.error('Error inesperado: $e');
    }
  }

  // ── Obtener todos los usuarios ────────────────────────────────
  static Future<UsersListResponse> getAllUsers({
    required String token,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    DatabaseService.setAuthToken(token);
    try {
      final response = await DatabaseService.get<dynamic>(
        DatabaseEndpoints.usuarios,
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return UsersListResponse(
          success: true,
          message: 'OK',
          data: _toList(response.data)
              .map((e) => UserData.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      return UsersListResponse.error(_errorMsg(response));
    } catch (e) {
      return UsersListResponse.error('Error inesperado: $e');
    }
  }

  // ── Obtener usuarios por rol ───────────────────────────────────
  /// [rolCodigo] = 'administrador' | 'inspector' | 'ayudante'
  static Future<UsersListResponse> getUsersByRole({
    required String token,
    required String rolCodigo,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
    String? role, // alias legacy — se ignora si se usa rolCodigo
  }) async {
    DatabaseService.setAuthToken(token);
    try {
      final response = await DatabaseService.get<dynamic>(
        DatabaseEndpoints.usuariosByRolCodigo(rolCodigo),
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return UsersListResponse(
          success: true,
          message: 'OK',
          data: _toList(response.data)
              .map((e) => UserData.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      return UsersListResponse.error(_errorMsg(response));
    } catch (e) {
      return UsersListResponse.error('Error inesperado: $e');
    }
  }

  // ── Actualizar usuario (multipart para foto, JSON sin foto) ────
  static Future<UserResponse> updateUser({
    required String token,
    required String userId,
    String? nombre,
    String? telefono,
    String? email,
    String? cedula,
    String? direccion,
    String? currentPassword,
    String? newPassword,
    File?   imageFile,
    bool    removeImage = false, // mantenido por compatibilidad
    int     maxRetries  = 2,
    Duration timeout    = const Duration(seconds: 15),
  }) async {
    DatabaseService.setAuthToken(token);

    final fields = <String, String>{};
    if (nombre          != null && nombre.isNotEmpty)          fields['nombre']          = nombre;
    if (telefono        != null && telefono.isNotEmpty)        fields['telefono']        = telefono;
    if (email           != null && email.isNotEmpty)           fields['email']           = email;
    if (cedula          != null && cedula.isNotEmpty)          fields['cedula']          = cedula;
    if (direccion       != null && direccion.isNotEmpty)       fields['direccion']       = direccion;
    if (currentPassword != null && currentPassword.isNotEmpty) fields['currentPassword'] = currentPassword;
    if (newPassword     != null && newPassword.isNotEmpty)     fields['password']        = newPassword;

    try {
      DatabaseResponse<Map<String, dynamic>> response;

      if (imageFile != null) {
        response = await _putMultipart(userId, fields, imageFile);
      } else {
        response = await DatabaseService.put<Map<String, dynamic>>(
          DatabaseEndpoints.usuarioById(userId),
          fields.map((k, v) => MapEntry(k, v as dynamic)),
          requiresAuth: true,
        );
      }

      if (response.success && response.data != null) {
        final map = _toMap(response.data!);
        if (map != null) {
          return UserResponse.success(UserData.fromJson(map),
              message: 'Usuario actualizado');
        }
        return UserResponse.error('Respuesta inválida');
      }
      return UserResponse.error(_errorMsg(response));
    } catch (e) {
      return UserResponse.error('Error inesperado: $e');
    }
  }

  /// Alias de compatibilidad para pantallas que llaman assignRole(role:...)
  static Future<UserResponse> assignRole({
    required String token,
    required String userId,
    required String role,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) => changeRole(token: token, userId: userId, rolCodigo: role);

  // ── Cambiar rol de usuario (solo admin) ───────────────────────
  static Future<UserResponse> changeRole({
    required String token,
    required String userId,
    required String rolCodigo,
  }) async {
    DatabaseService.setAuthToken(token);
    try {
      final response = await DatabaseService.patch<Map<String, dynamic>>(
        DatabaseEndpoints.usuarioRol(userId),
        {'rol': rolCodigo},
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        final map = _toMap(response.data!);
        if (map != null) return UserResponse.success(UserData.fromJson(map));
        return UserResponse.error('Respuesta inválida');
      }
      return UserResponse.error(_errorMsg(response));
    } catch (e) {
      return UserResponse.error('Error inesperado: $e');
    }
  }

  // ── Validaciones ──────────────────────────────────────────────
  static String? validateUserData({
    String? nombre,
    String? telefono,
    String? email,
    String? cedula,
  }) {
    if (nombre != null && nombre.trim().isNotEmpty) {
      if (nombre.trim().length < 2) return 'El nombre debe tener al menos 2 caracteres';
      if (nombre.trim().length > 100) return 'El nombre no debe exceder 100 caracteres';
    }
    if (telefono != null && telefono.trim().isNotEmpty) {
      if (!RegExp(r'^\+593[0-9]{9}$').hasMatch(telefono.trim())) {
        return 'Formato de teléfono inválido (+593XXXXXXXXX)';
      }
    }
    if (email != null && email.trim().isNotEmpty) {
      if (!RegExp(r'^[\w\-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
        return 'Formato de email inválido';
      }
    }
    if (cedula != null && cedula.trim().isNotEmpty) {
      if (!RegExp(r'^\d{10}$').hasMatch(cedula.trim())) {
        return 'La cédula debe tener 10 dígitos';
      }
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) return null;
    if (password.length < 6) return 'Mínimo 6 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Debe tener una mayúscula';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Debe tener un número';
    return null;
  }

  // ── Privados ──────────────────────────────────────────────────
  static Future<DatabaseResponse<Map<String, dynamic>>> _putMultipart(
    String userId,
    Map<String, String> fields,
    File imageFile,
  ) async {
    try {
      final uri = Uri.parse(
          '${DatabaseConfig.baseUrl}${DatabaseEndpoints.usuarioById(userId)}');
      final request = http.MultipartRequest('PUT', uri);
      if (DatabaseService.hasAuthToken()) {
        request.headers['Authorization'] =
            'Bearer ${DatabaseService.getAuthToken()}';
      }
      request.fields.addAll(fields);

      final ext = imageFile.path.toLowerCase();
      final mime = ext.endsWith('.png')
          ? MediaType('image', 'png')
          : MediaType('image', 'jpeg');
      request.files.add(
          await http.MultipartFile.fromPath('foto_perfil', imageFile.path,
              contentType: mime));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return DatabaseResponse.success(
            json.decode(response.body) as Map<String, dynamic>,
            statusCode: response.statusCode);
      }
      final err = json.decode(response.body);
      return DatabaseResponse.error(
          err?['error']?['message'] ?? 'Error del servidor');
    } catch (e) {
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  static Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('id_usuario') ||
          data.containsKey('nombre') ||
          data.containsKey('email')) return data;
      if (data['data'] is Map<String, dynamic>) return data['data'];
      if (data['user'] is Map<String, dynamic>) return data['user'];
    }
    return null;
  }

  static List<dynamic> _toList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) return data['data'];
      if (data['users'] is List) return data['users'];
    }
    return [];
  }

  static String _errorMsg(DatabaseResponse r) {
    if (r.statusCode == 404) return 'Recurso no encontrado';
    if (r.statusCode == 401) return 'Token expirado o inválido';
    if (r.statusCode == 403) return 'Acceso denegado';
    if (r.statusCode == 400) return r.error ?? 'Datos inválidos';
    if (r.statusCode != null && r.statusCode! >= 500) {
      return 'Error interno del servidor';
    }
    return r.error ?? 'Error desconocido';
  }

  static void clearAuthToken()  => DatabaseService.clearAuthToken();
  static bool hasAuthToken()    => DatabaseService.hasAuthToken();
  static Future<bool> checkServerConnection() async {
    final r = await DatabaseService.checkConnection();
    return r.success;
  }
}
