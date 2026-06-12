class HomeResponse {
  final bool success;
  final String message;
  final HomeData? data;
  final String? error;

  HomeResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? HomeData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
      'error': error,
    };
  }

  factory HomeResponse.success(HomeData data, {String message = 'Datos obtenidos correctamente'}) {
    return HomeResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  factory HomeResponse.error(String error) {
    return HomeResponse(
      success: false,
      message: 'Error',
      error: error,
    );
  }
}

class HomeData {
  final UserInfo userInfo;
  final HomeStatistics statistics;

  HomeData({
    required this.userInfo,
    required this.statistics,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      userInfo: UserInfo.fromJson(json['userInfo'] ?? {}),
      statistics: HomeStatistics.fromJson(json['statistics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userInfo': userInfo.toJson(),
      'statistics': statistics.toJson(),
    };
  }
}

class UserInfo {
  final String idUsuario;
  final String nombre;
  final String email;
  final String rol;

  UserInfo({
    required this.idUsuario,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    String userId = '';
    if (json['id_usuario'] != null) {
      userId = json['id_usuario'].toString();
    } else if (json['userId'] != null) {
      userId = json['userId'].toString();
    }

    return UserInfo(
      idUsuario: userId,
      nombre: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      rol: json['rol']?.toString() ?? json['rol_codigo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'email': email,
      'rol': rol,
    };
  }
}

class HomeStatistics {
  final int totalEdificios;
  final int edificiosEvaluados;
  final int edificiosPendientes;
  final int inspeccionesRealizadas;

  HomeStatistics({
    required this.totalEdificios,
    required this.edificiosEvaluados,
    required this.edificiosPendientes,
    required this.inspeccionesRealizadas,
  });

  factory HomeStatistics.fromJson(Map<String, dynamic> json) {
    return HomeStatistics(
      totalEdificios: json['totalEdificios'] ?? 0,
      edificiosEvaluados: json['edificiosEvaluados'] ?? 0,
      edificiosPendientes: json['edificiosPendientes'] ?? 0,
      inspeccionesRealizadas: json['inspeccionesRealizadas'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEdificios': totalEdificios,
      'edificiosEvaluados': edificiosEvaluados,
      'edificiosPendientes': edificiosPendientes,
      'inspeccionesRealizadas': inspeccionesRealizadas,
    };
  }
}