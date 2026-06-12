import 'dart:convert';

/// Una fila raw del endpoint GET /permisos/rol/:rolId
class PermisoRaw {
  final String opcion;
  final String nombreOpcion;
  final String? ruta;
  final String? icono;
  final int? orden;
  final String accion;
  final String nombreAccion;

  const PermisoRaw({
    required this.opcion,
    required this.nombreOpcion,
    this.ruta,
    this.icono,
    this.orden,
    required this.accion,
    required this.nombreAccion,
  });

  factory PermisoRaw.fromJson(Map<String, dynamic> j) => PermisoRaw(
        opcion:       j['opcion']?.toString()       ?? '',
        nombreOpcion: j['nombre_opcion']?.toString() ?? '',
        ruta:         j['ruta']?.toString(),
        icono:        j['icono']?.toString(),
        orden:        j['orden'] is int ? j['orden'] : int.tryParse(j['orden']?.toString() ?? ''),
        accion:       j['accion']?.toString()       ?? '',
        nombreAccion: j['nombre_accion']?.toString() ?? '',
      );
}

/// Un módulo consolidado — con todas sus acciones permitidas
class MenuItemPermiso {
  final String codigo;
  final String nombre;
  final String? ruta;
  final String? icono;
  final int orden;
  final List<String> acciones;

  MenuItemPermiso({
    required this.codigo,
    required this.nombre,
    this.ruta,
    this.icono,
    required this.orden,
    required this.acciones,
  });

  // ── Helpers de acciones ──────────────────────────────────────────
  bool get tieneAcceso   => acciones.contains('acceso');
  bool get puedeVer      => acciones.contains('ver');
  bool get puedeCrear    => acciones.contains('crear');
  bool get puedeEditar   => acciones.contains('editar');
  bool get puedeEliminar => acciones.contains('eliminar');
  bool get puedeCambiarEstado => acciones.contains('cambiar_estado');

  // ── Construcción desde lista raw ────────────────────────────────
  /// Agrupa por opcion y devuelve solo los que tienen accion='acceso'
  static List<MenuItemPermiso> fromRawList(List<PermisoRaw> raw) {
    final Map<String, MenuItemPermiso> map = {};
    for (final p in raw) {
      if (!map.containsKey(p.opcion)) {
        map[p.opcion] = MenuItemPermiso(
          codigo:   p.opcion,
          nombre:   p.nombreOpcion,
          ruta:     p.ruta,
          icono:    p.icono,
          orden:    p.orden ?? 99,
          acciones: [],
        );
      }
      if (!map[p.opcion]!.acciones.contains(p.accion)) {
        map[p.opcion]!.acciones.add(p.accion);
      }
    }

    // Solo los que tienen 'acceso', ordenados por orden
    return map.values
        .where((m) => m.tieneAcceso && m.codigo != 'dashboard')
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
  }

  // ── Serialización (caché en SharedPreferences) ──────────────────
  Map<String, dynamic> toJson() => {
        'codigo':   codigo,
        'nombre':   nombre,
        'ruta':     ruta,
        'icono':    icono,
        'orden':    orden,
        'acciones': acciones,
      };

  factory MenuItemPermiso.fromJson(Map<String, dynamic> j) => MenuItemPermiso(
        codigo:   j['codigo']?.toString() ?? '',
        nombre:   j['nombre']?.toString() ?? '',
        ruta:     j['ruta']?.toString(),
        icono:    j['icono']?.toString(),
        orden:    j['orden'] is int ? j['orden'] : int.tryParse(j['orden']?.toString() ?? '') ?? 99,
        acciones: (j['acciones'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );

  // ── Lista desde JSON en cache ────────────────────────────────────
  static List<MenuItemPermiso> listFromJsonString(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => MenuItemPermiso.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJsonString(List<MenuItemPermiso> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());
}
