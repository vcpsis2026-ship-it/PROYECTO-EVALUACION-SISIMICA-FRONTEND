import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../core/services/building_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/building_form_data.dart';
import 'exten_revis.dart';
class BuildingRegistry5Screen extends StatefulWidget {
  const BuildingRegistry5Screen({super.key});

  @override
  State<BuildingRegistry5Screen> createState() =>
      _BuildingRegistry5ScreenState();
}

class _BuildingRegistry5ScreenState extends State<BuildingRegistry5Screen> {
  final _formKey = GlobalKey<FormState>();
  final comentariosController = TextEditingController();
  String? _tipoSueloSeleccionado;
  bool _isLoading = false;

  final List<Map<String, String>> _tipoSueloOpciones = [
    {"valor": "A", "texto": "A: Roca dura"},
    {"valor": "B", "texto": "B: Roca semi-dura"},
    {"valor": "C", "texto": "C: Suelo denso"},
    {"valor": "D", "texto": "D: Suelo rígido"},
    {"valor": "E", "texto": "E: Suelo blando"},
    {"valor": "F", "texto": "F: Suelo pobre"},
  ];

  @override
  void initState() {
    super.initState();
    final formData = BuildingFormData();
    comentariosController.text = formData.comentarios;
    _tipoSueloSeleccionado = formData.tipoSueloSeleccionado.isNotEmpty 
        ? formData.tipoSueloSeleccionado 
        : null;
  }

  Future<void> _guardarEdificio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final formData = BuildingFormData();
      // Guardar últimos datos
      formData.comentarios = comentariosController.text;
      formData.tipoSueloSeleccionado = _tipoSueloSeleccionado ?? 'D';

      double latitudParsed = double.tryParse(formData.latitud) ?? 0.0;
      double longitudParsed = double.tryParse(formData.longitud) ?? 0.0;
      int? pisosParsed = int.tryParse(formData.pisos);
      double? areaParsed = double.tryParse(formData.area);
      int? anioConstruccionParsed = int.tryParse(formData.anioConstruccion);
      int? anioCodigoParsed = int.tryParse(formData.anioCodigo);
      int? anioAmpliacionParsed = int.tryParse(formData.anioAmpliacion);
      int? unidadesParsed = int.tryParse(formData.unidades);

      // Validaciones de campos obligatorios
      if (pisosParsed == null || pisosParsed <= 0) {
        _showErrorDialog('Error de validación', 'Ingrese un número de pisos válido');
        return;
      }
      if (areaParsed == null || areaParsed <= 0) {
        _showErrorDialog('Error de validación', 'Ingrese un área total válida');
        return;
      }
      if (anioConstruccionParsed == null ||
          anioConstruccionParsed < 1800 ||
          anioConstruccionParsed > DateTime.now().year) {
        _showErrorDialog('Error de validación', 'Ingrese un año de construcción válido');
        return;
      }
      if (anioCodigoParsed == null ||
          anioCodigoParsed < 1900 ||
          anioCodigoParsed > DateTime.now().year) {
        _showErrorDialog(
            'Error de validación',
            'Ingrese un año del código válido entre 1900 y ${DateTime.now().year}'
        );
        return;
      }
      if (formData.ampliacionSi &&
          (anioAmpliacionParsed == null || anioAmpliacionParsed <= anioConstruccionParsed)) {
        _showErrorDialog('Error de validación',
            'El año de ampliación debe ser posterior al año de construcción');
        return;
      }
      if (unidadesParsed == null || unidadesParsed <= 0) {
        _showErrorDialog('Error de validación', 'Ingrese un número de unidades válido');
        return;
      }

      // Llamada al servicio para crear el edificio
      final response = await BuildingService.createBuilding(
        nombreEdificio: formData.nombre.trim(),
        direccion: formData.direccion.trim(),
        ciudad: formData.ciudad.trim().isNotEmpty ? formData.ciudad.trim() : 'nom',
        codigoPostal: formData.codigoPostal.trim(),
        usoPrincipal: formData.usoPrincipal.trim(),
        latitud: latitudParsed,
        longitud: longitudParsed,
        numeroPisos: pisosParsed,
        areaTotalPiso: areaParsed,
        anioConstruccion: anioConstruccionParsed,
        anioCodigo: anioCodigoParsed,
        ampliacion: formData.ampliacionSi,
        anioAmpliacion: anioAmpliacionParsed,
        ocupacion: formData.ocupacion.trim(),
        historico: formData.historico,
        albergue: formData.albergue,
        gubernamental: formData.gubernamental,
        unidades: unidadesParsed,
        otrasIdentificaciones: formData.tipoSueloSeleccionado,
        comentarios: formData.comentarios.trim().isNotEmpty
            ? formData.comentarios.trim()
            : null,
        fotoEdificio: formData.fotoEdificioXFile,
        graficoEdificio: formData.graficoEdificioXFile,
      );

      if (response.success) {
        _showSuccessDialog(
          '¡Éxito!',
          'Edificio registrado correctamente.',
          response.buildingId ?? 0,
        );
      } else {
        _showErrorDialog('Error', response.error ?? 'Error desconocido');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Error inesperado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message, int bId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              // Cierra el diálogo
              Navigator.of(context).pop(); 

              final formData = BuildingFormData();
              formData.clear();

              // Redirigir a Home y limpiar historial de registro
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
            child: const Text('Más tarde'),
          ),
          TextButton(
            onPressed: () {
              // Cierra el diálogo
              Navigator.of(context).pop(); 

              final formData = BuildingFormData();

              final String nombreGuardado = formData.nombre;
              final String direccionGuardada = formData.direccion;
              final String anioConstruccionGuardado = formData.anioConstruccion;
              final String pisosGuardado = formData.pisos;
              final String ciudadGuardada = formData.ciudad;

              // Limpiamos los datos del formulario global
              formData.clear();

              // Redirigir a inspección y limpiar el historial para que no regrese al formulario
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => ExtensionRevisionPage(
                    idEdificio: bId,
                    nombreEdificio: nombreGuardado,
                    direccion: direccionGuardada,
                    anioConstruccion: anioConstruccionGuardado,
                    tipoSuelo: _tipoSueloSeleccionado ?? 'D',
                    numeroPisos: int.tryParse(pisosGuardado) ?? 0,
                    ciudad: ciudadGuardada,
                  ),
                ),
                ModalRoute.withName('/home'), // Regresará al Home o BuildingsScreen
              );
            },
            child: const Text('Comenzar Inspección'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      labelStyle: const TextStyle(color: AppColors.gray500),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tipo de suelo y observaciones"),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo tipo de suelo
              const Text(
                "Tipo de suelo",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoSueloSeleccionado,
                items: _tipoSueloOpciones
                    .map((e) => DropdownMenuItem(
                  value: e["valor"],
                  child: Text(e["texto"]!),
                ))
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (v) => setState(() => _tipoSueloSeleccionado = v),
                decoration: _inputDecoration("Seleccione tipo de suelo"),
              ),
              const SizedBox(height: 10),

              // Mensaje de aviso
              const Text(
                "Aviso: Si no se conoce asumir tipo D",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Campo de comentarios
              const Text(
                "Comentarios adicionales",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: comentariosController,
                decoration: _inputDecoration("Comentarios (opcional)"),
                maxLines: 4,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 30),

              // Mostrar resumen de datos
              Builder(
                builder: (context) {
                  final formData = BuildingFormData();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Resumen del edificio:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("Nombre: ${formData.nombre}"),
                          Text("Dirección: ${formData.direccion}"),
                          Text("Ciudad: ${formData.ciudad}"),
                          Text("Año del codigo: ${formData.anioCodigo}"),
                          Text("Pisos: ${formData.pisos}"),
                          Text("Área por piso: ${formData.area} m²"),
                          Text("Año construcción: ${formData.anioConstruccion}"),
                          Text("Unidades: ${formData.unidades}"),
                          Text("Fotos: ${formData.fotoEdificioXFile != null ? 'Sí' : 'No'}"),
                          Text("Gráfico: ${formData.graficoEdificioXFile != null ? 'Sí' : 'No'}"),
                        ],
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 20),

              // Botones Guardar y Regresar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarEdificio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text("Guardando edificio..."),
                    ],
                  )
                      : const Text(
                    "Guardar edificio",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                    final formData = BuildingFormData();
                    formData.comentarios = comentariosController.text;
                    formData.tipoSueloSeleccionado = _tipoSueloSeleccionado ?? '';
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Regresar",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    comentariosController.dispose();
    super.dispose();
  }
}
