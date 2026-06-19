import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/database_config.dart'; // Importa tu config de URL

class InspectionService {
  /// Función para enviar la inspección al backend
  static Future<bool> saveInspection(Map<String, dynamic> data, String token) async {
    try {
      // Usamos la URL que ya tienes configurada en tu proyecto
      // El endpoint debe coincidir con el que pusimos en Node.js (/inspecciones)
      final url = Uri.parse('${DatabaseConfig.getServerUrl()}/inspecciones');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Enviamos el token para que authMiddleware nos deje pasar
        },
        body: jsonEncode(data),
      );

      print('Estado del servidor: ${response.statusCode}');
      print('Respuesta del servidor: ${response.body}');

      // Si el servidor responde 201 (Creado), todo salió bien
      return response.statusCode == 201;
    } catch (e) {
      print('Error al conectar con el servidor: $e');
      return false;
    }
  }
}