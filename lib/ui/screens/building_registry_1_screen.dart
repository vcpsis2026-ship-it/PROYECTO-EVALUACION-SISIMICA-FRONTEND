import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/building_form_data.dart';
import 'building_registry_2_screen.dart';

class BuildingRegistry1Screen extends StatefulWidget {
  const BuildingRegistry1Screen({super.key});

  @override
  State<BuildingRegistry1Screen> createState() => _BuildingRegistry1ScreenState();
}

class _BuildingRegistry1ScreenState extends State<BuildingRegistry1Screen> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final direccionController = TextEditingController();
  final codigoPostalController = TextEditingController();

  // Usar XFile + bytes para compatibilidad web
  XFile? _fotoXFile;
  XFile? _graficoXFile;
  Uint8List? _fotoBytes;
  Uint8List? _graficoBytes;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final formData = BuildingFormData();
    nombreController.text = formData.nombre;
    direccionController.text = formData.direccion;
    codigoPostalController.text = formData.codigoPostal;
    _fotoXFile = formData.fotoEdificioXFile;
    _graficoXFile = formData.graficoEdificioXFile;
    
    // Cargar bytes si las imágenes existen
    if (_fotoXFile != null) {
      _fotoXFile!.readAsBytes().then((bytes) {
        if (mounted) setState(() => _fotoBytes = bytes);
      });
    }
    if (_graficoXFile != null) {
      _graficoXFile!.readAsBytes().then((bytes) {
        if (mounted) setState(() => _graficoBytes = bytes);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  Future<void> _pickFile(bool isFoto) async {
    final picker = ImagePicker();

    // Mostrar opciones al usuario
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Galería"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (!kIsWeb) // Cámara no siempre disponible en web
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Cámara"),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
          ],
        ),
      ),
    );

    if (source == null) return; // Usuario canceló

    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    // Leer bytes (funciona en web y mobile)
    final bytes = await pickedFile.readAsBytes();
    final fileSize = bytes.length;
    final mimeType = lookupMimeType(pickedFile.name) ?? lookupMimeType(pickedFile.path);

    // VALIDACIÓN DE TAMAÑO (10MB máximo)
    if (fileSize > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El archivo no puede superar los 10 MB")),
      );
      return;
    }

    // VALIDACIÓN DE FORMATO - Solo JPG/PNG
    if (mimeType != "image/jpeg" && mimeType != "image/png") {
      final String tipoArchivo = isFoto ? "foto" : "gráfico";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("La $tipoArchivo debe ser JPEG o PNG únicamente"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Log para verificar archivo seleccionado
    print('Archivo seleccionado:');
    print('  Tipo: ${isFoto ? "Foto" : "Gráfico"}');
    print('  Nombre: ${pickedFile.name}');
    print('  MIME: $mimeType');
    print('  Tamaño: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

    setState(() {
      if (isFoto) {
        _fotoXFile = pickedFile;
        _fotoBytes = bytes;
      } else {
        _graficoXFile = pickedFile;
        _graficoBytes = bytes;
      }
    });

    // Mostrar confirmación al usuario
    final String tipoArchivo = isFoto ? "Foto" : "Gráfico";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$tipoArchivo seleccionado correctamente"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }



  void _siguiente() async {
    if (_formKey.currentState!.validate()) {
      if (_fotoXFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes subir al menos una foto de la fachada")),
        );
        return;
      }

      final formData = BuildingFormData();
      formData.nombre = nombreController.text;
      formData.direccion = direccionController.text;
      formData.codigoPostal = codigoPostalController.text;
      formData.fotoEdificioXFile = _fotoXFile;
      formData.graficoEdificioXFile = _graficoXFile;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BuildingRegistry2Screen(),
        ),
      );
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  Widget _labeledTextFormField(String label, TextEditingController controller, String? Function(String?)? validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(),
          validator: validator,
        ),
      ],
    );
  }

  Widget _previewWidget(Uint8List? bytes, XFile? xFile, String label) {
    return Column(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: bytes != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                    Icons.error,
                    size: 60,
                    color: AppColors.error
                );
              },
            ),
          )
              : const Icon(Icons.image, size: 60, color: AppColors.gray500),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _pickFile(label == "Foto"),
          child: Text("Subir $label"),
        ),
        // Mostrar información del archivo seleccionado
        if (xFile != null) ...[
          const SizedBox(height: 4),
          Text(
            xFile.name,
            style: const TextStyle(fontSize: 10, color: AppColors.gray500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: const Text(
          "Registro Edificio",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Sección de archivos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(width: 150, child: _previewWidget(_fotoBytes, _fotoXFile, "Foto")),
                        SizedBox(width: 150, child: _previewWidget(_graficoBytes, _graficoXFile, "Gráfico")),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Campos de texto con labels arriba
                    _labeledTextFormField(
                      "Nombre del edificio",
                      nombreController,
                          (v) => v == null || v.isEmpty
                          ? "Campo obligatorio"
                          : v.length > 100
                          ? "Máximo 100 caracteres"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _labeledTextFormField(
                      "Dirección",
                      direccionController,
                          (v) => v != null && v.length > 255
                          ? "Máximo 255 caracteres"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _labeledTextFormField(
                      "Código Postal",
                      codigoPostalController,
                          (v) => v != null && v.length > 10
                          ? "Máximo 10 caracteres"
                          : null,
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _siguiente,
                      child: const Text(
                        "Siguiente",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/building');
                      },
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
      ),
    );
  }
}
