import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_application_1/core/config/database_config.dart';
import 'package:http/http.dart' as http;

import '../../data/models/home_response.dart';

class HomeService {
  static const String _baseUrl = DatabaseConfig.baseUrl;

  /// Método principal: obtiene datos del usuario usando el endpoint correcto
  static Future<HomeResponse> getUserDataWithStats({
    required String token,
    required String userId,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Usar directamente el endpoint /users/:id
      final profileResponse = await getUserProfile(
        token: token,
        userId: userId,
        maxRetries: maxRetries,
        timeout: timeout,
      );

      if (!profileResponse.success) {
        return profileResponse;
      }

      // Las estadísticas pueden agregarse aquí si se implementa el endpoint
      // Por ahora usar estadísticas por defecto
      return profileResponse;

    } catch (e) {
      return HomeResponse.error('Error al obtener datos del usuario: $e');
    }
  }

  /// Obtiene el perfil del usuario usando /users/:id
  static Future<HomeResponse> getUserProfile({
    required String token,
    required String userId,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;

        final response = await http.get(
          Uri.parse('$_baseUrl/usuarios/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(timeout);

        print('Profile response status: ${response.statusCode}');
        print('Profile response body: ${response.body}');

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);

          // MANEJO SEGURO DE DIFERENTES ESTRUCTURAS DE RESPUESTA
          Map<String, dynamic> userData;

          if (decoded is List) {
            // El backend retornó una lista — buscar nuestro usuario por ID
            print('Respuesta es una lista con ${decoded.length} elementos, buscando userId=$userId');
            final match = decoded.firstWhere(
              (item) => item['id_usuario']?.toString() == userId,
              orElse: () => null,
            );
            if (match == null) {
              return HomeResponse.error('Usuario no encontrado en la lista (ID: $userId)');
            }
            userData = Map<String, dynamic>.from(match);
          } else if (decoded is Map<String, dynamic>) {
            final responseData = decoded;
            // El servidor puede retornar diferentes estructuras:
            // - Directamente los datos del usuario
            // - { data: {userData} }
            // - { user: {userData} }
            if (responseData.containsKey('data')) {
              userData = responseData['data'] as Map<String, dynamic>;
              print('Datos encontrados en responseData["data"]');
            } else if (responseData.containsKey('user')) {
              userData = responseData['user'] as Map<String, dynamic>;
              print('Datos encontrados en responseData["user"]');
            } else {
              // Asumir que responseData ES los datos del usuario
              userData = responseData;
              print('Usando responseData directamente como userData');
            }
          } else {
            return HomeResponse.error('Formato de respuesta no reconocido');
          }

          // Validar que userData tiene los campos mínimos necesarios
          if (!userData.containsKey('id_usuario') && !userData.containsKey('userId')) {
            print('⚠️ Warning: userData no contiene id_usuario ni userId');
            print('Estructura recibida: ${userData.keys.toList()}');
          }

          final homeData = HomeData(
            userInfo: UserInfo.fromJson(userData),
            statistics: HomeStatistics(
              totalEdificios: 0,
              edificiosEvaluados: 0,
              edificiosPendientes: 0,
              inspeccionesRealizadas: 0,
            ),
          );

          return HomeResponse.success(homeData, message: 'Perfil obtenido correctamente');

        } else if (response.statusCode == 404) {
          return HomeResponse.error('Usuario no encontrado con ID: $userId');
        } else {
          String errorMessage;
          try {
            final errorData = json.decode(response.body);
            // Adaptarse a la estructura de error del servidor
            if (errorData['error'] != null && errorData['error']['message'] != null) {
              errorMessage = errorData['error']['message'];
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            } else {
              errorMessage = 'Error al obtener perfil';
            }
          } catch (e) {
            errorMessage = 'Error ${response.statusCode}';
          }

          // Si es error de cliente (4xx), no reintentar
          if (response.statusCode >= 400 && response.statusCode < 500) {
            return HomeResponse.error(errorMessage);
          }

          // Para errores de servidor (5xx), continuar con retry si no es el último intento
          if (attempts >= maxRetries) {
            return HomeResponse.error(errorMessage);
          }

          print('Error ${response.statusCode}, reintentando... (intento $attempts/$maxRetries)');
        }

      } on SocketException catch (e) {
        print('SocketException in getUserProfile: ${e.message}');
        if (attempts >= maxRetries) {
          return HomeResponse.error('Error de conexión: ${e.message}');
        }
        print('Error de conexión, reintentando en ${attempts} segundos...');
        await Future.delayed(Duration(seconds: attempts));

      } on TimeoutException catch (e) {
        print('TimeoutException in getUserProfile: $e');
        if (attempts >= maxRetries) {
          return HomeResponse.error('Tiempo de espera agotado: $e');
        }
        print('Timeout, reintentando en ${attempts} segundos...');
        await Future.delayed(Duration(seconds: attempts));

      } catch (e) {
        print('General error in getUserProfile: $e');
        if (attempts >= maxRetries) {
          return HomeResponse.error('Error inesperado: $e');
        }
        print('Error general, reintentando en ${attempts} segundos...');
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    return HomeResponse.error('Error después de $maxRetries intentos');
  }

  /// OPCIONAL: Obtener estadísticas si se implementa el endpoint
  static Future<HomeResponse> getUserStatistics({
    required String token,
    required String userId,
    int maxRetries = 1,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/usuarios/$userId/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return HomeResponse.fromJson(responseData);
      } else {
        // Si no existe el endpoint, retornar estadísticas por defecto
        return HomeResponse.success(
            HomeData(
              userInfo: UserInfo(idUsuario: '', nombre: '', email: '', rol: ''),
              statistics: HomeStatistics(
                totalEdificios: 0,
                edificiosEvaluados: 0,
                edificiosPendientes: 0,
                inspeccionesRealizadas: 0,
              ),
            )
        );
      }
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      // Retornar estadísticas vacías si falla
      return HomeResponse.success(
          HomeData(
            userInfo: UserInfo(idUsuario: '', nombre: '', email: '', rol: ''),
            statistics: HomeStatistics(
              totalEdificios: 0,
              edificiosEvaluados: 0,
              edificiosPendientes: 0,
              inspeccionesRealizadas: 0,
            ),
          )
      );
    }
  }

  /// DEPRECATED: Método anterior usando /users/inspectors
  /// Mantener solo para compatibilidad si es necesario
  @Deprecated('Usar getUserProfile con userId específico')
  static Future<HomeResponse> getHomeData({
    required String token,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Este método ya no debería usarse
    return HomeResponse.error('Método obsoleto. Usar getUserProfile con userId específico.');
  }
}