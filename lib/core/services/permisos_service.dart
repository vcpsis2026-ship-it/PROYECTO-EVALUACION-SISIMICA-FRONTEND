import 'package:shared_preferences/shared_preferences.dart';
import '../constants/database_endpoints.dart';
import 'database_service.dart';
import '../../data/models/permiso_model.dart';

class PermisosService {
  static const String _kCacheKey = 'menu_permisos_json';
  static const String _kRolIdKey = 'rolId';

  // ── Fetch desde el backend y guarda en cache ────────────────────
  /// [rolId] es el UUID/integer del rol (campo rol_id del perfil del usuario)
  static Future<List<MenuItemPermiso>> fetchAndCache(String rolId) async {
    try {
      final response = await DatabaseService.get<dynamic>(
        DatabaseEndpoints.permisosByRol(rolId),
        requiresAuth: true,
      );

      if (!response.success || response.data == null) {
        print('[PermisosService] Error fetching: ${response.error}');
        return loadFromCache();
      }

      final rawList = _parseRawList(response.data);
      if (rawList.isEmpty) return loadFromCache();

      final items = MenuItemPermiso.fromRawList(rawList);

      // Guardar en cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCacheKey, MenuItemPermiso.listToJsonString(items));

      print('[PermisosService] ${items.length} módulos cargados: ${items.map((m) => m.codigo).join(", ")}');
      return items;

    } catch (e) {
      print('[PermisosService] Exception: $e');
      return loadFromCache();
    }
  }

  // ── Carga desde SharedPreferences ──────────────────────────────
  static Future<List<MenuItemPermiso>> loadFromCache() async {
    try {
      final prefs  = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kCacheKey);
      if (cached == null || cached.isEmpty) return [];
      return MenuItemPermiso.listFromJsonString(cached);
    } catch (e) {
      print('[PermisosService] Cache error: $e');
      return [];
    }
  }

  // ── Guarda rolId ────────────────────────────────────────────────
  static Future<void> saveRolId(String rolId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRolIdKey, rolId);
  }

  // ── Lee rolId ───────────────────────────────────────────────────
  static Future<String?> getRolId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRolIdKey);
  }

  // ── Limpia cache (logout) ───────────────────────────────────────
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCacheKey);
    await prefs.remove(_kRolIdKey);
  }

  // ── Parseo interno ──────────────────────────────────────────────
  static List<PermisoRaw> _parseRawList(dynamic data) {
    List<dynamic> list = [];
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      if (data['data'] is List) list = data['data'];
      else if (data['permisos'] is List) list = data['permisos'];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(PermisoRaw.fromJson)
        .toList();
  }
}
