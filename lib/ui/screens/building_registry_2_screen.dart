import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_application_1/ui/screens/building_registry_3_screen.dart';
import '../../core/helpers/navigation_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/building_form_data.dart';
import 'building_registry_3_screen.dart';

class LocationService {
  // Verificar si los servicios de ubicación están habilitados
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Verificar permisos de ubicación
  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Solicitar permisos de ubicación
  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  // Obtener la posición actual
  static Future<Position?> getCurrentPosition() async {
    try {
      // Verificar si los servicios están habilitados
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados.');
      }

      // Verificar permisos
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      // Obtener la posición actual con configuración personalizada
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  // Obtener dirección a partir de coordenadas (Geocoding inverso)
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
      return null;
    } catch (e) {
      print('Error obteniendo dirección: $e');
      return null;
    }
  }

  // Obtener coordenadas a partir de una dirección (Geocoding)
  static Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      print('Error obteniendo coordenadas: $e');
      return null;
    }
  }
}

class BuildingRegistry2Screen extends StatefulWidget {


  const BuildingRegistry2Screen({super.key});

  @override
  State<BuildingRegistry2Screen> createState() =>
      _BuildingRegistry2ScreenState();
}

class _BuildingRegistry2ScreenState extends State<BuildingRegistry2Screen> {
  final _formKey = GlobalKey<FormState>();

  final otrasIdentificacionesController = TextEditingController();
  final usoController = TextEditingController();
  final latitudController = TextEditingController();
  final longitudController = TextEditingController();
  final inspectorController = TextEditingController();
  final fechaController = TextEditingController();
  final horaController = TextEditingController();

  int _selectedIndex = 0;
  bool _isLoadingLocation = false;
  String _locationStatus = '';

  @override
  void initState() {
    super.initState();
    final formData = BuildingFormData();
    otrasIdentificacionesController.text = formData.otrasIdentificaciones;
    usoController.text = formData.usoPrincipal;
    latitudController.text = formData.latitud;
    longitudController.text = formData.longitud;
    inspectorController.text = formData.inspector;
    fechaController.text = formData.fecha;
    horaController.text = formData.hora;
    
    // Intentar obtener coordenadas de la dirección si está disponible
    if (formData.direccion.isNotEmpty && formData.latitud.isEmpty) {
      _getCoordinatesFromAddress();
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      NavigationHelper.navigateToHome(context, isReplacement: true);
    } else if (index == 1) {
      NavigationHelper.navigateToProfile(context, isReplacement: false);
    }
  }

  // Obtener ubicación actual del GPS
  void _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Obteniendo ubicación...';
    });

    try {
      Position? position = await LocationService.getCurrentPosition();

      if (position != null) {
        setState(() {
          latitudController.text = position.latitude.toStringAsFixed(8);
          longitudController.text = position.longitude.toStringAsFixed(8);
          _locationStatus = 'Ubicación obtenida exitosamente';
        });

        // Mostrar snackbar de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ubicación obtenida: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _locationStatus = 'No se pudo obtener la ubicación';
        });
        _showErrorDialog('No se pudo obtener la ubicación actual. Verifica que el GPS esté activado y los permisos estén concedidos.');
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Error: $e';
      });
      _showErrorDialog('Error obteniendo ubicación: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Obtener coordenadas a partir de la dirección del edificio
  void _getCoordinatesFromAddress() async {
    final formData = BuildingFormData();
    if (formData.direccion.isEmpty) return;

    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Buscando coordenadas...';
    });

    try {
      Location? location = await LocationService.getCoordinatesFromAddress(formData.direccion);

      if (location != null) {
        setState(() {
          latitudController.text = location.latitude.toStringAsFixed(8);
          longitudController.text = location.longitude.toStringAsFixed(8);
          _locationStatus = 'Coordenadas encontradas por dirección';
        });
      } else {
        setState(() {
          _locationStatus = 'No se encontraron coordenadas para la dirección';
        });
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Error buscando coordenadas: $e';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error de Ubicación'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _siguiente() {
    if (_formKey.currentState!.validate()) {
      final formData = BuildingFormData();
      formData.otrasIdentificaciones = otrasIdentificacionesController.text;
      formData.usoPrincipal = usoController.text;
      formData.latitud = latitudController.text;
      formData.longitud = longitudController.text;
      formData.inspector = inspectorController.text;
      formData.fecha = fechaController.text;
      formData.hora = horaController.text;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BuildingRegistry3Screen(),
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

  Widget _labeledTextFormField(
      String label,
      TextEditingController controller, {
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
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
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        // Campos de latitud y longitud con iconos
        Row(
          children: [
            Expanded(
              child: _labeledTextFormField(
                "Latitud",
                latitudController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la latitud';
                  }
                  double? lat = double.tryParse(value);
                  if (lat == null || lat < -90 || lat > 90) {
                    return 'Latitud inválida (-90 a 90)';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            // Botón para obtener ubicación desde dirección
            IconButton(
              onPressed: _isLoadingLocation ? null : _getCoordinatesFromAddress,
              icon: Icon(Icons.search_outlined),
              tooltip: 'Buscar por dirección',
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _labeledTextFormField(
                "Longitud",
                longitudController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la longitud';
                  }
                  double? lng = double.tryParse(value);
                  if (lng == null || lng < -180 || lng > 180) {
                    return 'Longitud inválida (-180 a 180)';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            // Botón para obtener ubicación actual
            IconButton(
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              icon: _isLoadingLocation
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(Icons.my_location),
              tooltip: 'Mi ubicación actual',
              color: AppColors.primary,
            ),
          ],
        ),

        // Mensaje de estado
        if (_locationStatus.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _locationStatus.contains('Error') ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _locationStatus.contains('Error') ? Colors.red : Colors.green,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _locationStatus.contains('Error') ? Icons.error_outline : Icons.check_circle_outline,
                  size: 16,
                  color: _locationStatus.contains('Error') ? Colors.red : Colors.green,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: _locationStatus.contains('Error') ? Colors.red[700] : Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
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
                    _labeledTextFormField(
                      "Otras identificaciones",
                      otrasIdentificacionesController,
                    ),
                    const SizedBox(height: 16),

                    _labeledTextFormField("Uso del edificio", usoController),
                    const SizedBox(height: 16),

                    // Sección de ubicación mejorada
                    _buildLocationSection(),
                    const SizedBox(height: 16),

                    _labeledTextFormField(
                      "Nombre del inspector",
                      inspectorController,
                    ),
                    const SizedBox(height: 16),

                    // Fecha y Hora en fila horizontal
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Fecha (mm/dd/yy)",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: fechaController,
                                decoration: _inputDecoration(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Hora",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: horaController,
                                decoration: _inputDecoration(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
                    formData.otrasIdentificaciones = otrasIdentificacionesController.text;
                    formData.usoPrincipal = usoController.text;
                    formData.latitud = latitudController.text;
                    formData.longitud = longitudController.text;
                    formData.inspector = inspectorController.text;
                    formData.fecha = fechaController.text;
                    formData.hora = horaController.text;
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Regresar",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}