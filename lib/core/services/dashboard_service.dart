import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/database_config.dart';
import '../../data/models/dashboard_stats.dart';

class DashboardService {
  static const String _baseUrl = DatabaseConfig.baseUrl;

  /// Obtiene las estadísticas del dashboard de administrador
  static Future<DashboardStats?> getAdminStats({
    required String token,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      debugPrint('DashboardService: Solicitando estadísticas...');

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeout);

      debugPrint('DashboardService: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('DashboardService: Datos recibidos correctamente');
        return DashboardStats.fromJson(data);
      } else {
        debugPrint('DashboardService: Error ${response.statusCode} - ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      debugPrint('DashboardService: Error de conexión: ${e.message}');
      return null;
    } on TimeoutException catch (_) {
      debugPrint('DashboardService: Timeout');
      return null;
    } catch (e) {
      debugPrint('DashboardService: Error inesperado: $e');
      return null;
    }
  }
}
