class DatabaseConfig {

  static const String baseUrl =
      'https://proyecto-evaluacion-sisimica-backend-0p6n.onrender.com';

  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  static String getServerUrl() {
    return baseUrl;
  }
}
