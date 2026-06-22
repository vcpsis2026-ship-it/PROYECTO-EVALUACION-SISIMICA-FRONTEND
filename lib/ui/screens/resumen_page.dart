import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/inspection_service.dart';
import '../../data/models/building_list_response.dart';
import 'reporte_detalle_screen.dart';

class ResumenPage extends StatefulWidget {
  final int idEdificio;
  final String nombreEdificio;
  final String direccion;
  final String anioConstruccion;
  final String tipoSuelo;
  final int numeroPisos;
  final String ciudad;
  final String alcanceExterior;
  final String alcanceInterior;
  final bool revisionPlanos;
  final String contacto;
  final Map<String, bool> otrosPeligros;
  final String evaluacionDetallada;

  const ResumenPage({
    super.key,
    required this.idEdificio,
    required this.nombreEdificio,
    required this.direccion,
    required this.anioConstruccion,
    required this.tipoSuelo,
    required this.numeroPisos,
    required this.ciudad,
    required this.alcanceExterior,
    required this.alcanceInterior,
    required this.revisionPlanos,
    required this.contacto,
    required this.otrosPeligros,
    required this.evaluacionDetallada,
  });

  @override
  State<ResumenPage> createState() => _ResumenPageState();
}

class _ResumenPageState extends State<ResumenPage> {
  bool _isSaving = false;
  late double _puntajeCalculado;

  @override
  void initState() {
    super.initState();
    _puntajeCalculado = _ejecutarCalculoDinamico();
  }

  double _ejecutarCalculoDinamico() {
    double score = 10.0;
    int anio = int.tryParse(widget.anioConstruccion) ?? 2026;
    if (anio < 1980) score -= 2.5; else if (anio < 2000) score -= 1.0;
    if (widget.tipoSuelo == 'F') score -= 3.0; else if (widget.tipoSuelo == 'E') score -= 1.5; else if (widget.tipoSuelo == 'D') score -= 0.5;
    if (widget.numeroPisos > 6) score -= 1.5; else if (widget.numeroPisos > 3) score -= 0.5;
    widget.otrosPeligros.forEach((key, value) { if (value) score -= 0.5; });
    return score.clamp(0.5, 10.0);
  }

  Future<void> _guardarYFinalizar() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      final userId = prefs.getString('userId') ?? '0';

      final Map<String, dynamic> data = {
        "id_edificio": widget.idEdificio,
        "id_usuario": userId,
        "fecha_inspeccion": DateTime.now().toIso8601String().split('T')[0],
        "puntuacion_final": _puntajeCalculado,
        "estado": "completada",
        "alcance_exterior": widget.alcanceExterior,
        "alcance_interior": widget.alcanceInterior,
        "revision_planos": widget.revisionPlanos,
        "fuente_suelo": widget.tipoSuelo,
        "fuente_peligros": "Observación técnica",
        "contacto_persona": widget.contacto,
        "requiere_nivel2": _puntajeCalculado < 5.0,
        "otros_peligros": widget.otrosPeligros,
        "requiere_evaluacion_detallada": widget.evaluacionDetallada,
        "peligro_no_estructural": widget.evaluacionDetallada.contains("Sí") ? "Peligro identificado" : "Ninguno",
        "observaciones_generales": "Inspección finalizada desde el móvil",
      };

      final exito = await InspectionService.saveInspection(data, token);

      if (exito) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ReporteDetalleScreen(
              edificio: BuildingData(
                idEdificio: widget.idEdificio,
                nombreEdificio: widget.nombreEdificio,
                direccion: widget.direccion,
                anioConstruccion: int.tryParse(widget.anioConstruccion),
                otrasIdentificaciones: widget.tipoSuelo,
              ),
              puntuacion: _puntajeCalculado,
            ),
          ),
              (route) => route.isFirst,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar la inspección (Verifique la consola para detalles)")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al conectar con el servidor: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de Inspección'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("Resumen de respuestas:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                _buildTile("Edificio", widget.nombreEdificio, Icons.business),
                _buildTile("Puntaje Calculado", _puntajeCalculado.toStringAsFixed(1), Icons.analytics, highlight: true),
                _buildTile("Tipo de Suelo", widget.tipoSuelo, Icons.layers),
                _buildTile("Alcance Exterior", widget.alcanceExterior, Icons.visibility),
                _buildTile("Evaluación Detallada", widget.evaluacionDetallada, Icons.assignment_late),
                const SizedBox(height: 20),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      "¿Requiere Nivel 2? - A base del calculo del sistema: ${_puntajeCalculado < 5.0 ? 'SÍ' : 'NO'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _guardarYFinalizar,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("GUARDAR Y FINALIZAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTile(String l, String v, IconData icon, {bool highlight = false}) => ListTile(
    leading: Icon(icon, color: Colors.blueGrey),
    title: Text(l, style: const TextStyle(fontSize: 14, color: Colors.grey)),
    subtitle: Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: highlight ? Colors.red : Colors.black87)),
  );
}