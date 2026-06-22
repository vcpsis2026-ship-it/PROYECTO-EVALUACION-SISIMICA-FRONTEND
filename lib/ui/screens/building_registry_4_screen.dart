import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/helpers/navigation_helper.dart';
import '../../data/models/building_form_data.dart';
import 'building_registry_5_screen.dart';

class BuildingRegistry4Screen extends StatefulWidget {
  const BuildingRegistry4Screen({super.key});

  @override
  State<BuildingRegistry4Screen> createState() =>
      _BuildingRegistry4ScreenState();
}

class _BuildingRegistry4ScreenState extends State<BuildingRegistry4Screen> {
  final _formKey = GlobalKey<FormState>();
  final unidadesController = TextEditingController();
  final otraOcupacionController = TextEditingController();

  String? _tipoSeleccionado;
  int _selectedIndex = 0;

  final List<Map<String, String>> _tipoOpciones = [
    {"value": "Asamblea", "label": "Asamblea"},
    {"value": "Comercial", "label": "Comercial"},
    {"value": "Servicios Em.", "label": "Servicios Em."},
    {"value": "Industrial", "label": "Industrial"},
    {"value": "Oficina", "label": "Oficina"},
    {"value": "Escuela", "label": "Escuela"},
    {"value": "Almacén", "label": "Almacén"},
    {"value": "Residencial", "label": "Residencial"},
    {"value": "Histórico", "label": "Histórico"},
    {"value": "Albergue", "label": "Albergue"},
    {"value": "Gubernamental", "label": "Gubernamental"},
    {"value": "Herramientas", "label": "Herramientas"},
    {"value": "Otro (Especificar)", "label": "Otro (Especificar)"},
  ];

  @override
  void initState() {
    super.initState();
    final formData = BuildingFormData();
    unidadesController.text = formData.unidades;
    
    if (formData.ocupacion.isNotEmpty) {
      bool found = false;
      for (var opc in _tipoOpciones) {
        if (opc['value'] == formData.ocupacion) {
          _tipoSeleccionado = formData.ocupacion;
          found = true;
          break;
        }
      }
      if (!found) {
        _tipoSeleccionado = "Otro (Especificar)";
        otraOcupacionController.text = formData.ocupacion;
      }
    }
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < 2) {
      setState(() => _selectedIndex = index);
      if (index == 0) {
        NavigationHelper.navigateToHome(context, isReplacement: true);
      } else if (index == 1) {
        NavigationHelper.navigateToProfile(context, isReplacement: false);
      }
    }
  }

  void _siguiente() {
    if (_formKey.currentState!.validate()) {
      final formData = BuildingFormData();
      formData.unidades = unidadesController.text;
      
      String ocupacionFinal = _tipoSeleccionado ?? "";
      if (ocupacionFinal == "Otro (Especificar)") {
        ocupacionFinal = otraOcupacionController.text.trim();
      }
      formData.ocupacion = ocupacionFinal;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BuildingRegistry5Screen(),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.gray500, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Ocupación y unidades",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF00BCD4),
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de Ocupación
                    const Text(
                      "Ocupación",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Container con dropdown de tipo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tipo",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: _tipoSeleccionado,
                            decoration: _inputDecoration("Seleccione tipo"),
                            items: _tipoOpciones.map((opcion) {
                              return DropdownMenuItem<String>(
                                value: opcion['value'],
                                child: Text(opcion['label']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _tipoSeleccionado = value;
                              });
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? "Seleccione un tipo"
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // Campo "Otra ocupación"
                          const Text(
                            "Otra ocupación",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: otraOcupacionController,
                            decoration: _inputDecoration(
                                "Si no selecciona, escriba aquí"),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sección Número de unidades
                    const Text(
                      "Número de unidades",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: unidadesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "Unidades",
                              hintStyle: const TextStyle(
                                  color: Colors.black54, fontSize: 14),
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide:
                                BorderSide(color: AppColors.gray300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide:
                                BorderSide(color: AppColors.gray300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                            ),
                            style: const TextStyle(fontSize: 14),
                            validator: (v) => v == null || v.isEmpty
                                ? "Ingrese el número de unidades"
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Botón Siguiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _siguiente,
                      child: const Text(
                        "Siguiente",
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
                      onPressed: () {
                        final formData = BuildingFormData();
                        formData.unidades = unidadesController.text;
                        String ocupacionFinal = _tipoSeleccionado ?? "";
                        if (ocupacionFinal == "Otro (Especificar)") {
                          ocupacionFinal = otraOcupacionController.text.trim();
                        }
                        formData.ocupacion = ocupacionFinal;
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
