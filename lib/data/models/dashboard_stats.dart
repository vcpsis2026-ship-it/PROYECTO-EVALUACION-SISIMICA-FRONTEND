class DashboardStats {
  final int totalEdificios;
  final int totalInspecciones;
  final int totalInspectores;
  final int totalAyudantes;
  final DistribucionPuntuacion distribucionPuntuacion;
  final List<TopEdificio> topEdificios;

  DashboardStats({
    required this.totalEdificios,
    required this.totalInspecciones,
    required this.totalInspectores,
    required this.totalAyudantes,
    required this.distribucionPuntuacion,
    required this.topEdificios,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalEdificios: _parseInt(json['totalEdificios']),
      totalInspecciones: _parseInt(json['totalInspecciones']),
      totalInspectores: _parseInt(json['totalInspectores']),
      totalAyudantes: _parseInt(json['totalAyudantes']),
      distribucionPuntuacion: DistribucionPuntuacion.fromJson(
        json['distribucionPuntuacion'] ?? {},
      ),
      topEdificios: (json['topEdificios'] as List<dynamic>?)
              ?.map((e) => TopEdificio.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory DashboardStats.empty() {
    return DashboardStats(
      totalEdificios: 0,
      totalInspecciones: 0,
      totalInspectores: 0,
      totalAyudantes: 0,
      distribucionPuntuacion: DistribucionPuntuacion.empty(),
      topEdificios: [],
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class DistribucionPuntuacion {
  final int riesgoAlto;
  final int riesgoMedio;
  final int riesgoBajo;

  DistribucionPuntuacion({
    required this.riesgoAlto,
    required this.riesgoMedio,
    required this.riesgoBajo,
  });

  int get total => riesgoAlto + riesgoMedio + riesgoBajo;

  factory DistribucionPuntuacion.fromJson(Map<String, dynamic> json) {
    return DistribucionPuntuacion(
      riesgoAlto: DashboardStats._parseInt(json['riesgoAlto']),
      riesgoMedio: DashboardStats._parseInt(json['riesgoMedio']),
      riesgoBajo: DashboardStats._parseInt(json['riesgoBajo']),
    );
  }

  factory DistribucionPuntuacion.empty() {
    return DistribucionPuntuacion(
      riesgoAlto: 0,
      riesgoMedio: 0,
      riesgoBajo: 0,
    );
  }
}

class TopEdificio {
  final String nombreEdificio;
  final int totalInspecciones;

  TopEdificio({
    required this.nombreEdificio,
    required this.totalInspecciones,
  });

  factory TopEdificio.fromJson(Map<String, dynamic> json) {
    return TopEdificio(
      nombreEdificio: json['nombre_edificio']?.toString() ?? 'Sin nombre',
      totalInspecciones: DashboardStats._parseInt(json['total_inspecciones']),
    );
  }
}
