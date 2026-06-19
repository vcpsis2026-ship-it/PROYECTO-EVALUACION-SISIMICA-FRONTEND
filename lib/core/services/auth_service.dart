import '../constants/database_endpoints.dart';
import 'database_service.dart';
import '../../data/models/database_response.dart';
import '../../data/models/auth_response.dart';

class AuthService {
  // ── LOGIN ──────────────────────────────────────────────────────
  static Future<AuthResponse> login({
    required String email,
    required String password,
    int maxRetries = 2,
  }) async {
    // 1. Verificar conexión
    try {
      final conn = await DatabaseService.checkConnection();
      if (!conn.success) {
        return AuthResponse.failure(
            error: 'Sin conexión al servidor. ${conn.error}');
      }
    } catch (e) {
      return AuthResponse.failure(error: 'Error de conexión: $e');
    }

    // 2. Intentar login
    int attempt = 0;
    while (attempt < maxRetries) {
      attempt++;
      try {
        print('[AuthService] Login intento $attempt/$maxRetries → $email');

        final response = await DatabaseService.post<Map<String, dynamic>>(
          DatabaseEndpoints.login,
          {'email': email.trim(), 'password': password},
        );

        if (response.success && response.data != null) {
          final data    = response.data!;
          final success = data['success'] == true;
          final token   = data['token']?.toString();
          final userId  = data['userId']?.toString(); // UUID string

          if (!success || token == null || userId == null) {
            return AuthResponse.failure(
                error: 'Respuesta inválida del servidor');
          }

          // Guardar token en memoria + SharedPreferences
          await DatabaseService.setAuthToken(token);

          // 3. Obtener perfil del usuario para nombre, rol y rolId
          String? nombre;
          String? rolCodigo;
          String? rolId;
          try {
            final userResp = await DatabaseService.get<dynamic>(
              DatabaseEndpoints.usuarioById(userId),
              requiresAuth: true,
            );
            if (userResp.success && userResp.data != null) {
              final raw = userResp.data;
              Map<String, dynamic> ud = {};
              if (raw is Map<String, dynamic>) {
                ud = raw;
              } else if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
                // Backend devolvió un array — buscar nuestro usuario
                final match = raw.firstWhere(
                  (item) => item['id_usuario']?.toString() == userId,
                  orElse: () => raw.first,
                );
                ud = Map<String, dynamic>.from(match);
              }
              nombre    = ud['nombre']?.toString();
              rolCodigo = ud['rol_codigo']?.toString();
              rolId     = ud['rol_id']?.toString();
            }
          } catch (e) {
            print('[AuthService] No se pudo obtener perfil: $e');
          }

          print('[AuthService] Login OK → userId=$userId rol=$rolCodigo');

          return AuthResponse.success(
            token:     token,
            userId:    userId,
            rolId:     rolId,
            nombre:    nombre,
            rolCodigo: rolCodigo,
            message:   nombre != null
                ? '¡Bienvenido, $nombre!'
                : '¡Login exitoso!',
          );
        } else {
          // Error 4xx → no reintentar
          if (response.statusCode != null && response.statusCode! >= 400 &&
              response.statusCode! < 500) {
            return AuthResponse.failure(
              error: response.error ?? 'Credenciales inválidas',
              statusCode: response.statusCode,
            );
          }
          // Error de red → reintentar
          if (attempt >= maxRetries) {
            return AuthResponse.failure(
              error: response.error ??
                  'Error de conexión después de $maxRetries intentos',
            );
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        print('[AuthService] Error en intento $attempt: $e');
        if (attempt >= maxRetries) {
          return AuthResponse.failure(
              error: 'Error de conexión después de $maxRetries intentos: $e');
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    return AuthResponse.failure(error: 'Error inesperado en el login');
  }

  // ── LOGOUT ────────────────────────────────────────────────────
  static Future<void> logout() async {
    print('[AuthService] Cerrando sesión');
    await DatabaseService.clearAuthToken();
  }

  // ── ESTADO DE SESIÓN ──────────────────────────────────────────
  static bool  isLoggedIn()     => DatabaseService.hasAuthToken();
  static String? getCurrentToken() => DatabaseService.getAuthToken();

  // ── RECUPERACIÓN DE CONTRASEÑA ────────────────────────────────
  static Future<DatabaseResponse> forgotPassword({
    String? email,
    String? telefono, // mantenido por compatibilidad (el backend no lo usa aún)
  }) async {
    return DatabaseService.post(
      DatabaseEndpoints.forgotPassword,
      {'email': email},
    );
  }

  static Future<DatabaseResponse> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return DatabaseService.post(
      DatabaseEndpoints.resetPassword,
      {'token': token, 'newPassword': newPassword},
    );
  }
}
