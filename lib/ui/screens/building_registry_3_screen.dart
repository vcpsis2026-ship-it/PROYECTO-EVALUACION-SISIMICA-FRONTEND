import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/helpers/navigation_helper.dart';
import '../../data/models/building_form_data.dart';
import 'building_registry_4_screen.dart';

class BuildingRegistry3Screen extends StatefulWidget {
  const BuildingRegistry3Screen({super.key});

  @override
  State<BuildingRegistry3Screen> createState() => _BuildingRegistry3ScreenState();
}

class _BuildingRegistry3ScreenState extends State<BuildingRegistry3Screen> {
  final _formKey = GlobalKey<FormState>();

  final pisosController = TextEditingController();
  final areaController = TextEditingController();
  final anioConstruccionController = TextEditingController();
  final anioCodigoController = TextEditingController();
  final anioAmpliacionController = TextEditingController();

  bool _ampliacionSi = false;
  String _pisosVerificacion = "EST";
  String _areaVerificacion = "REAL";
  String _anioConstruccionVerificacion = "EST";
  String _anioCodigoVerificacion = "EST";
  String _anioAmpliacionVerificacion = "EST";

  final List<String> _verificacionOpciones = ["REAL", "EST", "DNK"];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final formData = BuildingFormData();
    pisosController.text = formData.pisos;
    areaController.text = formData.area;
    anioConstruccionController.text = formData.anioConstruccion;
    anioCodigoController.text = formData.anioCodigo;
    anioAmpliacionController.text = formData.anioAmpliacion;
    _ampliacionSi = formData.ampliacionSi;
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      NavigationHelper.navigateToHome(context, isReplacement: true);
    } else if (index == 1) {
      NavigationHelper.navigateToProfile(context, isReplacement: false);
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
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      counterText: "", // Ocultar el contador de caracteres
    );
  }

  Widget _buildFieldWithDropdown(
      String label,
      TextEditingController controller,
      String selectedVerification,
      Function(String?) onVerificationChanged,
      {TextInputType keyboardType = TextInputType.text,
        int? maxLength,
        String? Function(String?)? validator}
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLength: maxLength,
                decoration: _inputDecoration(""),
                validator: validator,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedVerification,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    items: _verificacionOpciones
                        .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: onVerificationChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _siguiente() {
    if (_formKey.currentState!.validate()) {
      final formData = BuildingFormData();
      formData.pisos = pisosController.text;
      formData.area = areaController.text;
      formData.anioConstruccion = anioConstruccionController.text;
      formData.anioCodigo = anioCodigoController.text;
      formData.anioAmpliacion = anioAmpliacionController.text;
      formData.ampliacionSi = _ampliacionSi;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BuildingRegistry4Screen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Características estructurales",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
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
                    _buildFieldWithDropdown(
                      "Número de Pisos",
                      pisosController,
                      _pisosVerificacion,
                          (value) => setState(() => _pisosVerificacion = value!),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      validator: (v) => v == null || v.isEmpty ? "Ingrese el número de pisos" : null,
                    ),
                    const SizedBox(height: 20),

                    _buildFieldWithDropdown(
                      "Área total de piso (m2)",
                      areaController,
                      _areaVerificacion,
                          (value) => setState(() => _areaVerificacion = value!),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || v.isEmpty ? "Ingrese el área total" : null,
                    ),
                    const SizedBox(height: 20),

                    _buildFieldWithDropdown(
                      "Año de construcción",
                      anioConstruccionController,
                      _anioConstruccionVerificacion,
                          (value) => setState(() => _anioConstruccionVerificacion = value!),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),
                    const SizedBox(height: 20),

                    _buildFieldWithDropdown(
                      "Año de código",
                      anioCodigoController,
                      _anioCodigoVerificacion,
                          (value) => setState(() => _anioCodigoVerificacion = value!),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      validator: (v) {
                        print('Valor ingresado: "$v"'); // <-- para depuración
                        if (v == null || v.trim().isEmpty) return 'Ingrese un año del código';
                        final parsed = int.tryParse(v.trim());
                        print('Valor parseado: $parsed'); // <-- para depuración
                        if (parsed == null || parsed < 1900 || parsed > DateTime.now().year) {
                          return 'Ingrese un año del código válido entre 1900 y ${DateTime.now().year}';
                        }
                        return null;
                      },

                    ),
                    const SizedBox(height: 20),

                    // Sección de ampliación
                    const Text(
                      "¿Ampliación?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Seleccione si hay ampliación",
                      style: TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _ampliacionSi = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _ampliacionSi ? AppColors.primary : Colors.white,
                                border: Border.all(
                                  color: _ampliacionSi ? AppColors.primary : AppColors.gray300,
                                  width: _ampliacionSi ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  "SI",
                                  style: TextStyle(
                                    color: _ampliacionSi ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _ampliacionSi = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_ampliacionSi ? AppColors.primary : Colors.white,
                                border: Border.all(
                                  color: !_ampliacionSi ? AppColors.primary : AppColors.gray300,
                                  width: !_ampliacionSi ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  "NO",
                                  style: TextStyle(
                                    color: !_ampliacionSi ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_ampliacionSi) ...[
                      const SizedBox(height: 20),
                      _buildFieldWithDropdown(
                        "Año de ampliación",
                        anioAmpliacionController,
                        _anioAmpliacionVerificacion,
                            (value) => setState(() => _anioAmpliacionVerificacion = value!),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Mensaje informativo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade300, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.red.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mensaje",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Cuando la información no se pueda verificar, deberá seleccionar:",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "• REAL - Dato reales/existentes",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "• EST - Dato estimado/manual",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "• DNK - No se conoce o vacío",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón Siguiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                        formData.pisos = pisosController.text;
                        formData.area = areaController.text;
                        formData.anioConstruccion = anioConstruccionController.text;
                        formData.anioCodigo = anioCodigoController.text;
                        formData.anioAmpliacion = anioAmpliacionController.text;
                        formData.ampliacionSi = _ampliacionSi;
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Regresar",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
