import 'package:flutter/foundation.dart';
import '../constants/database_endpoints.dart';
import 'database_service.dart';

/// Servicio para consumir los endpoints de inspecciones por edificio,
/// incluyendo archivos, comentarios y resultados.
class InspectionDetailService {
  // ── Inspecciones de un edificio ──────────────────────────────
  static Future<List<Map<String, dynamic>>> getByBuilding(int idEdificio) async {
    try {
      final response = await DatabaseService.get<dynamic>(
        DatabaseEndpoints.inspeccionesByEdificio(idEdificio),
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return _toList(response.data);
      }
      debugPrint('Error obteniendo inspecciones del edificio $idEdificio: ${response.error}');
      return [];
    } catch (e) {
      debugPrint('Excepción en getByBuilding: $e');
      return [];
    }
  }

  // ── Detalle de una inspección ────────────────────────────────
  static Future<Map<String, dynamic>?> getDetail(int idInspeccion) async {
    try {
      final response = await DatabaseService.get<dynamic>(
        DatabaseEndpoints.inspeccionById(idInspeccion),
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return _toMap(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Excepción en getDetail: $e');
      return null;
    }
  }

  // ── Archivos de una inspección ───────────────────────────────
  static Future<List<Map<String, dynamic>>> getFiles(int idInspeccion) async {
    try {
      final response = await DatabaseService.get<dynamic>(
        DatabaseEndpoints.inspeccionArchivos(idInspeccion),
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return _toList(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('Excepción en getFiles: $e');
      return [];
    }
  }

  // ── Comentarios de una inspección ────────────────────────────
  static Future<List<Map<String, dynamic>>> getComments(int idInspeccion) async {
    try {
      final response = await DatabaseService.get<dynamic>(
        DatabaseEndpoints.inspeccionComentarios(idInspeccion),
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return _toList(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('Excepción en getComments: $e');
      return [];
    }
  }

  // ── Resultados de una inspección ─────────────────────────────
  static Future<List<Map<String, dynamic>>> getResults(int idInspeccion) async {
    try {
      final response = await DatabaseService.get<dynamic>(
        DatabaseEndpoints.inspeccionResultados(idInspeccion),
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return _toList(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('Excepción en getResults: $e');
      return [];
    }
  }

  // ── Helpers de conversión ────────────────────────────────────
  static List<Map<String, dynamic>> _toList(dynamic data) {
    if (data is List) {
      return data.map((e) {
        if (e is Map<String, dynamic>) return e;
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  static Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }
}
