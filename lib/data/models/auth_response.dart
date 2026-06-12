class AuthResponse {
  final bool success;
  final String? token;
  final String? userId;
  final String? nombre;
  final String? rolId;
  final String? rolCodigo;
  final String message;
  final String? error;
  final int? statusCode;

  AuthResponse._({
    required this.success,
    this.token,
    this.userId,
    this.nombre,
    this.rolId,
    this.rolCodigo,
    required this.message,
    this.error,
    this.statusCode,
  });

  factory AuthResponse.success({
    String? token,
    String? userId,
    String? nombre,
    String? rolId,
    String? rolCodigo,
    required String message,
  }) {
    return AuthResponse._(
      success: true,
      token: token,
      userId: userId,
      nombre: nombre,
      rolId: rolId,
      rolCodigo: rolCodigo,
      message: message,
    );
  }

  // Respuesta de error
  factory AuthResponse.failure({
    required String error,
    int? statusCode,
  }) {
    return AuthResponse._(
      success: false,
      message: error,
      error: error,
      statusCode: statusCode,
    );
  }

  String? get userIdValue => userId;
  String get userNameValue => nombre ?? 'Usuario';
  String get userRoleValue => rolCodigo ?? '';

  // Verificar si tiene token válido
  bool get hasValidToken => token != null && token!.isNotEmpty;

  // Debug: Mostrar información del auth response
  Map<String, dynamic> toDebugMap() {
    return {
      'success': success,
      'token': token != null ? '${token!.substring(0, 10)}...' : null,
      'userId': userId,
      'nombre': nombre,
      'message': message,
      'error': error,
      'statusCode': statusCode,
    };
  }
}