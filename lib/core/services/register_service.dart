import 'dart:io';
import 'package:flutter_application_1/core/services/auth_service.dart';
import '../constants/database_endpoints.dart';
import 'database_service.dart';
import '../../data/models/database_response.dart';
import '../../data/models/register_response.dart';

class RegisterService {

  static Future<RegisterResponse> registerUser({
    required String username,
    required String role,
    required String email,
    required String phone,
    required String password,
    required String cedula,
    File? fotoPerfil,
    int maxRetries = 2,
  }) async {
    // Validaciones previas antes de enviar al servidor
    final validationError = _validateRegistrationData(
      username: username,
      role: role, // El rol configurado desde RegisterScreen
      email: email,
      phone: phone,
      password: password,
      cedula: cedula,
    );

    if (validationError != null) {
      return RegisterResponse.failure(error: validationError);
    }

    int attemptCount = 0;

    while (attemptCount < maxRetries) {
      attemptCount++;

      try {
        print('RegisterService: Intento $attemptCount/$maxRetries para $email');
        print('Registrando como: $role');

        // Usar multipart con el rol configurado
        final fields = {
          "nombre": username.trim(),
          "email": email.trim().toLowerCase(),
          "password": password,
          "rol": role, // USAR EL ROL QUE VIENE DEL REGISTER_SCREEN
          "cedula": cedula.trim(),
          "telefono": phone.replaceAll(RegExp(r'[^\d]'), ''),
        };

        // Procesar teléfono
        if (fields["telefono"]!.startsWith('593')) {
          fields["telefono"] = fields["telefono"]!.substring(3);
        }

        print('Enviando datos multipart: $fields');

        final response = await DatabaseService.postMultipart<Map<String, dynamic>>(
          DatabaseEndpoints.register,
          fields,
          file: fotoPerfil,
          fileFieldName: 'foto_perfil',
        );

        print('DEBUG: Respuesta de DatabaseService:');
        print('   Success: ${response.success}');
        print('   StatusCode: ${response.statusCode}');
        print('   Data: ${response.data}');
        print('   Error: ${response.error}');

        if (response.success) {
          // REGISTRO EXITOSO - Iniciar sesión automáticamente
          print('Registro exitoso, iniciando sesión automática...');

          final loginResponse = await AuthService.login(
            email: email,
            password: password,
          );

          if (loginResponse.success) {
            // Login exitoso después del registro
            print('Login automático exitoso');

            // Extraer id_usuario específicamente de la respuesta del registro
            final userIdFromRegister = response.data?['user']?['id_usuario'];

            // Crear RegisterResponse exitoso con token y datos completos
            return RegisterResponse.success(
              token: loginResponse.token,
              userId: userIdFromRegister,
              user: response.data?['user'], // Datos del usuario desde el registro
              message: 'Registro y login exitosos. ¡Bienvenido a SismosApp!',
            );
          } else {
            // El registro fue exitoso pero el login automático falló
            print('Registro exitoso pero login automático falló: ${loginResponse.error}');

            // Usar específicamente id_usuario del registro
            final userIdFromRegister = response.data?['user']?['id_usuario'];

            // Devolver éxito del registro pero sin token (sin login automático)
            return RegisterResponse.success(
              userId: userIdFromRegister,
              user: response.data?['user'],
              message: 'Registro exitoso. Por favor, inicia sesión manualmente.',
            );
          }
        } else {
          // ERROR EN EL REGISTRO
          // Manejar errores del cliente (4xx)
          if (response.statusCode != null &&
              response.statusCode! >= 400 &&
              response.statusCode! < 500) {
            final errorMessage = _extractErrorMessage(response);
            return RegisterResponse.failure(
              error: _getSpecificErrorMessage(response.statusCode!, errorMessage),
              statusCode: response.statusCode,
            );
          }

          // Error de servidor/conexión - continuar con retry
          print('Intento $attemptCount falló: ${response.error}');
          if (attemptCount >= maxRetries) {
            return RegisterResponse.failure(
              error: response.error ?? 'Error de conexión después de $maxRetries intentos',
              statusCode: response.statusCode,
            );
          }
        }
      } catch (e) {
        print('Error en intento $attemptCount: $e');

        if (attemptCount >= maxRetries) {
          return RegisterResponse.failure(
            error: 'Error de conexión después de $maxRetries intentos: $e',
          );
        }

        // Esperar antes del retry
        if (attemptCount < maxRetries) {
          print('Esperando 1 segundo antes del retry...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    return RegisterResponse.failure(
      error: 'Error inesperado en el registro',
    );
  }

  // VERIFICAR DISPONIBILIDAD DE EMAIL
  static Future<bool> checkEmailAvailability(String email) async {
    // Validación básica del formato antes de hacer la petición
    if (email.trim().isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return false;
    }

    try {
      print('Verificando disponibilidad de email: $email');

      final response = await DatabaseService.get<Map<String, dynamic>>(
        '/auth/check-email?email=${Uri.encodeComponent(email.trim().toLowerCase())}',
      );

      print('Respuesta del servidor para email: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data!;

        // Manejar diferentes formatos de respuesta
        bool available = false;

        if (data.containsKey('available')) {
          available = data['available'] == true;
        } else if (data.containsKey('exists')) {
          available = data['exists'] == false; // Si exists=false, entonces available=true
        } else if (data.containsKey('isAvailable')) {
          available = data['isAvailable'] == true;
        } else {
          // Si no hay campo específico, asumir disponible si success=true
          available = true;
        }

        print('Email $email ${available ? "disponible" : "no disponible"}');
        return available;
      } else {
        // Si hay error 404, podría significar que no existe (disponible)
        if (response.statusCode == 404) {
          print('Email $email disponible (404 - no encontrado)');
          return true;
        }

        print('Error en verificación de email: ${response.error}');
        return false; // En caso de error, asumir no disponible para seguridad
      }
    } catch (e) {
      print('Excepción verificando email: $e');
      return false; // En caso de error, asumir no disponible para seguridad
    }
  }

  // VALIDAR DISPONIBILIDAD DE USERNAME
  static Future<bool> checkUsernameAvailability(String username) async {
    // Validación básica antes de hacer la petición
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || trimmedUsername.length < 3) {
      return false;
    }

    try {
      print('Verificando disponibilidad de username: $trimmedUsername');

      final response = await DatabaseService.get<Map<String, dynamic>>(
        '/auth/check-username?username=${Uri.encodeComponent(trimmedUsername.toLowerCase())}',
      );

      print('Respuesta del servidor para username: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data!;

        // Manejar diferentes formatos de respuesta
        bool available = false;

        if (data.containsKey('available')) {
          available = data['available'] == true;
        } else if (data.containsKey('exists')) {
          available = data['exists'] == false; // Si exists=false, entonces available=true
        } else if (data.containsKey('isAvailable')) {
          available = data['isAvailable'] == true;
        } else {
          // Si no hay campo específico, asumir disponible si success=true
          available = true;
        }

        print('Username $trimmedUsername ${available ? "disponible" : "no disponible"}');
        return available;
      } else {
        // Si hay error 404, podría significar que no existe (disponible)
        if (response.statusCode == 404) {
          print('Username $trimmedUsername disponible (404 - no encontrado)');
          return true;
        }

        print('Error en verificación de username: ${response.error}');
        return false; // En caso de error, asumir no disponible para seguridad
      }
    } catch (e) {
      print('Excepción verificando username: $e');
      return false; // En caso de error, asumir no disponible para seguridad
    }
  }

  // MÉTODOS PRIVADOS AUXILIARES
  static String? _validateRegistrationData({
    required String username,
    required String role,
    required String email,
    required String phone,
    required String password,
    required String cedula,
  }) {
    // Validar cedula
    if (cedula.trim().isEmpty) {
      return 'La cédula es requerida';
    }

    // Validar username
    if (username.trim().isEmpty) {
      return 'El nombre de usuario es requerido';
    }
    if (username.trim().length < 3) {
      return 'El nombre de usuario debe tener al menos 3 caracteres';
    }
    if (username.trim().length > 50) {
      return 'El nombre de usuario no puede exceder 50 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(username.trim())) {
      return 'El nombre solo puede contener letras y espacios';
    }

    // VALIDAR ROL - ACEPTA TODOS LOS ROLES VÁLIDOS DEL SISTEMA
    const validRoles = ['administrador', 'inspector', 'ayudante'];
    if (!validRoles.contains(role.trim().toLowerCase())) {
      return 'Rol inválido. Debe ser: ${validRoles.join(', ')}';
    }

    // Validar email
    if (email.trim().isEmpty) {
      return 'El correo electrónico es requerido';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return 'Formato de correo electrónico inválido';
    }

    // Validar teléfono
    if (phone.trim().isEmpty) {
      return 'El número de teléfono es requerido';
    }
    if (!phone.startsWith('+')) {
      return 'El teléfono debe incluir el código de país (+593...)';
    }

    // Validar contraseña
    if (password.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      return 'La contraseña debe contener al menos un símbolo (!@#\$&*~)';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return 'La contraseña debe contener al menos una letra';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'La contraseña debe contener al menos un número';
    }

    return null; // Todo válido
  }

  static String _extractErrorMessage(DatabaseResponse<Map<String, dynamic>> response) {
    String errorMessage = 'Error desconocido';

    try {
      if (response.data != null) {
        final data = response.data;

        // Caso 1: { error: { message: "..." } }
        if (data is Map<String, dynamic> && data['error'] != null) {
          final errorObj = data['error'];
          if (errorObj is Map<String, dynamic> && errorObj['message'] != null) {
            errorMessage = errorObj['message'];
          }
        }
        // Caso 2: { message: "..." } directamente
        else if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'];
        }
        // Caso 3: String directo
        else if (data is String) {
          errorMessage = data as String;
        }
      }

      // Fallback al error del DatabaseResponse
      if (errorMessage == 'Error desconocido' && response.error != null) {
        errorMessage = response.error!;
      }
    } catch (e) {
      print('Error extrayendo mensaje: $e');
      errorMessage = response.error ?? 'Error de formato en la respuesta';
    }

    print('Mensaje de error extraído: $errorMessage');
    return errorMessage;
  }

  static String _getSpecificErrorMessage(int statusCode, String originalMessage) {
    switch (statusCode) {
      case 400:
        if (originalMessage.isEmpty || originalMessage.contains('HTTP 400')) {
          return 'Datos de registro inválidos. Verifique todos los campos.';
        }
        // Si el servidor envía un mensaje específico, usarlo
        if (originalMessage.toLowerCase().contains('username') || originalMessage.toLowerCase().contains('nombre')) {
          return 'El nombre de usuario no es válido o ya está en uso';
        }
        if (originalMessage.toLowerCase().contains('email')) {
          return 'El correo electrónico no es válido o ya está registrado';
        }
        if (originalMessage.toLowerCase().contains('password')) {
          return 'La contraseña no cumple con los requisitos de seguridad';
        }
        return originalMessage;

      case 409:
        if (originalMessage.isEmpty || originalMessage.contains('HTTP 409')) {
          return 'El email o usuario ya existe. Use credenciales diferentes.';
        }
        return originalMessage;

      case 422:
        if (originalMessage.isEmpty || originalMessage.contains('HTTP 422')) {
          return 'Formato de datos inválido. Revise email, teléfono y contraseña.';
        }
        return originalMessage;

      case 429:
        return 'Demasiados intentos de registro. Espere un momento e intente nuevamente.';

      case 500:
        if (originalMessage.isEmpty || originalMessage.contains('HTTP 500')) {
          return 'Error interno del servidor. Intente más tarde.';
        }
        return originalMessage;

      case 503:
        return 'Servicio temporalmente no disponible. Intente más tarde.';

      default:
        return originalMessage.isEmpty
            ? 'Error de registro (Código: $statusCode)'
            : originalMessage;
    }
  }

  // LIMPIAR DATOS DE REGISTRO (Útil para resetear formularios)
  static void clearRegistrationCache() {
    print('RegisterService: Limpiando cache de registro');
    // Aquí podrías limpiar cualquier dato temporal si es necesario
  }

  // OBTENER ESTADÍSTICAS DE REGISTRO (para admins)
  static Future<Map<String, dynamic>?> getRegistrationStats() async {
    try {
      final response = await DatabaseService.get<Map<String, dynamic>>(
        '/admin/registration-stats',
      );

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error obteniendo estadísticas de registro: $e');
      return null;
    }
  }
}