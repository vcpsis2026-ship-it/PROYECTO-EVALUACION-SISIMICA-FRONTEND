class DatabaseConfig {
  // ─────────────────────────────────────────────────────────────
  // CAMBIA ESTE VALOR SEGÚN TU ENTORNO DE PRUEBA:
  //   Emulador Android   → 'http://10.0.2.2:3000'
  //   Dispositivo físico → 'http://<IP-LOCAL>:3000'  (ej: 192.168.1.100)
  //   iOS Simulator/Web  → 'http://localhost:3000'
  //   Producción         → 'https://api.tudominio.com'
  // ─────────────────────────────────────────────────────────────
  static const String _host = 'http://localhost:3000';

  /// Base URL para todos los endpoints del API (incluye /api/v1)
  static const String baseUrl = '$_host/api/v1';

  /// URL raíz sin prefijo — usada solo para /health
  static const String rawBaseUrl = _host;

  static const int connectionTimeout = 30000;
  static const int receiveTimeout    = 30000;

  /// Compatibilidad con código existente — devuelve baseUrl con /api/v1
  static String getServerUrl() => baseUrl;
}
