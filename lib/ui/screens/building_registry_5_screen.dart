import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../core/services/building_service.dart';
import '../../core/theme/app_colors.dart';
import 'exten_revis.dart';
class BuildingRegistry5Screen extends StatefulWidget {
  final String nombre;
  final String direccion;
  final String ciudad;
  final String codigoPostal;
  final String uso;
  final String latitud;
  final String longitud;
  final String inspector;
  final String fecha;
  final String hora;
  final XFile? fotoEdificioXFile;
  final XFile? graficoEdificioXFile;
  final String pisos;
  final String area;
  final String anioConstruccion;
  final String anioCodigo;
  final bool ampliacionSi;
  final String anioAmpliacion;
  final String verificacion;
  final String ocupacion;
  final String unidades;
  final bool historico;
  final bool albergue;
  final bool gubernamental;

  const BuildingRegistry5Screen({
    super.key,
    this.nombre = '',
    this.direccion = '',
    this.ciudad = 'nom',
    this.codigoPostal = '',
    this.uso = '',
    this.latitud = '',
    this.longitud = '',
    this.inspector = '',
    this.fecha = '',
    this.hora = '',
    this.fotoEdificioXFile,
    this.graficoEdificioXFile,
    this.pisos = '',
    this.area = '',
    this.anioConstruccion = '',
    this.anioCodigo = '',
    this.ampliacionSi = false,
    this.anioAmpliacion = '',
    this.verificacion = '',
    this.ocupacion = '',
    this.unidades = '',
    this.historico = false,
    this.albergue = false,
    this.gubernamental = false,
  });

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
    // valor por defecto = D: Suelo rígido
    _tipoSueloSeleccionado = "D";
  }

  Future<void> _guardarEdificio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Parseo seguro de campos numéricos
      final latitudParsed = double.tryParse(widget.latitud.trim());
      final longitudParsed = double.tryParse(widget.longitud.trim());
      final pisosParsed = int.tryParse(widget.pisos.trim());
      final areaParsed = double.tryParse(widget.area.trim());
      final anioConstruccionParsed = int.tryParse(widget.anioConstruccion.trim());
      final anioCodigoText = widget.anioCodigo.trim();
      final anioCodigoParsed = int.tryParse(anioCodigoText);
      final anioAmpliacionParsed = widget.ampliacionSi && widget.anioAmpliacion.isNotEmpty
          ? int.tryParse(widget.anioAmpliacion.trim())
          : null;
      final unidadesParsed = int.tryParse(widget.unidades.trim());

      // Validaciones de campos obligatorios
      if (latitudParsed == null || longitudParsed == null) {
        _showErrorDialog('Error de validación', 'Ingrese latitud y longitud válidas');
        return;
      }
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
      if (widget.ampliacionSi &&
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
        nombreEdificio: widget.nombre.trim(),
        direccion: widget.direccion.trim(),
        ciudad: widget.ciudad.trim(),
        codigoPostal: widget.codigoPostal.trim(),
        usoPrincipal: widget.uso.trim(),
        latitud: latitudParsed,
        longitud: longitudParsed,
        numeroPisos: pisosParsed,
        areaTotalPiso: areaParsed,
        anioConstruccion: anioConstruccionParsed,
        anioCodigo: anioCodigoParsed,
        ampliacion: widget.ampliacionSi,
        anioAmpliacion: anioAmpliacionParsed,
        ocupacion: widget.ocupacion.trim(),
        historico: widget.historico,
        albergue: widget.albergue,
        gubernamental: widget.gubernamental,
        unidades: unidadesParsed,
        otrasIdentificaciones: _tipoSueloSeleccionado,
        comentarios: comentariosController.text.trim().isNotEmpty
            ? comentariosController.text.trim()
            : null,
        fotoEdificio: widget.fotoEdificioXFile,
        graficoEdificio: widget.graficoEdificioXFile,
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
              Navigator.of(context).pop(); // Cierra el diálogo

              // --- CORRECCIÓN CLAVE AQUÍ ---
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExtensionRevisionPage(
                    idEdificio: bId,
                    nombreEdificio: widget.nombre,
                    direccion: widget.direccion,
                    anioConstruccion: widget.anioConstruccion,
                    tipoSuelo: _tipoSueloSeleccionado ?? 'D',
                    numeroPisos: int.tryParse(widget.pisos) ?? 0,
                    ciudad: widget.ciudad,
                  ),
                ),
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
              Card(
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
                      Text("Nombre: ${widget.nombre}"),
                      Text("Dirección: ${widget.direccion}"),
                      Text("Ciudad: ${widget.ciudad}"),
                      Text("Año del codigo: ${widget.anioCodigo}"),
                      Text("Pisos: ${widget.pisos}"),
                      Text("Área por piso: ${widget.area} m²"),
                      Text("Año construcción: ${widget.anioConstruccion}"),
                      Text("Unidades: ${widget.unidades}"),
                      Text("Fotos: ${widget.fotoEdificioXFile != null ? 'Sí' : 'No'}"),
                      Text("Gráfico: ${widget.graficoEdificioXFile != null ? 'Sí' : 'No'}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón guardar
              ElevatedButton(
                onPressed: _isLoading ? null : _guardarEdificio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                  style: TextStyle(fontSize: 16),
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
