/// Rutas relativas al baseUrl ( http://host/api/v1 )
/// Todos los paths arrancan con '/'
class DatabaseEndpoints {
  DatabaseEndpoints._();

  // ── Auth ──────────────────────────────────────────────────────
  static const String login          = '/auth/login';
  static const String register       = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword  = '/auth/reset-password';

  // ── Usuarios ──────────────────────────────────────────────────
  /// GET   /usuarios          → lista todos
  /// GET   /usuarios/:id      → uno por UUID
  /// PUT   /usuarios/:id      → actualizar (multipart)
  /// PATCH /usuarios/:id/rol  → cambiar rol (solo admin)
  static const String usuarios = '/usuarios';

  /// GET /usuarios/byRol/:rolCodigo
  static const String usuariosByRol = '/usuarios/byRol';

  // ── Roles ─────────────────────────────────────────────────────
  /// GET  /roles                          → lista roles activos
  /// GET  /roles/usuario/:idUsuario       → roles de un usuario
  /// POST /roles/usuario/:idUsuario/asignar
  /// DELETE /roles/usuario/:idUsuario/remover
  static const String roles          = '/roles';
  static const String rolesByUsuario = '/roles/usuario';

  // ── Permisos ──────────────────────────────────────────────────
  /// GET /permisos/modulos
  /// GET /permisos/opciones
  /// GET /permisos/acciones
  /// GET /permisos/rol/:idRol
  static const String permisosModulos  = '/permisos/modulos';
  static const String permisosOpciones = '/permisos/opciones';
  static const String permisosAcciones = '/permisos/acciones';
  static const String permisosRol      = '/permisos/rol';

  // ── Edificios ─────────────────────────────────────────────────
  static const String edificios = '/edificios';
  /// Alias de compatibilidad con código legado que usa DatabaseEndpoints.buildings
  static const String buildings = edificios;

  // ── Inspecciones ──────────────────────────────────────────────
  static const String inspecciones = '/inspecciones';

  // ── Auditoría ─────────────────────────────────────────────────
  static const String auditoria = '/auditoria';

  // ── Helpers ───────────────────────────────────────────────────
  /// Construye: /usuarios/<uuid>
  static String usuarioById(String id) => '$usuarios/$id';

  /// Construye: /usuarios/<uuid>/rol
  static String usuarioRol(String id) => '$usuarios/$id/rol';

  /// Construye: /usuarios/byRol/<codigo>
  static String usuariosByRolCodigo(String codigo) => '$usuariosByRol/$codigo';

  /// Construye: /roles/usuario/<uuid>
  static String rolesByUsuarioId(String id) => '$rolesByUsuario/$id';

  /// Construye: /permisos/rol/<idRol>
  /// Construye: /permisos/rol/<idRol>
  static String permisosByRol(String idRol) => '$permisosRol/$idRol';

  // ── Inspecciones helpers ──────────────────────────────────────
  /// GET /inspecciones/edificio/<idEdificio>
  static String inspeccionesByEdificio(int id) => '$inspecciones/edificio/$id';

  /// GET /inspecciones/<id>
  static String inspeccionById(int id) => '$inspecciones/$id';

  /// GET /inspecciones/<id>/archivos
  static String inspeccionArchivos(int id) => '$inspecciones/$id/archivos';

  /// GET /inspecciones/<id>/comentarios
  static String inspeccionComentarios(int id) => '$inspecciones/$id/comentarios';

  /// GET /inspecciones/<id>/resultados
  static String inspeccionResultados(int id) => '$inspecciones/$id/resultados';
}
