import 'package:image_picker/image_picker.dart';

class BuildingFormData {
  static final BuildingFormData _instance = BuildingFormData._internal();
  factory BuildingFormData() => _instance;
  BuildingFormData._internal();

  // Screen 1
  String nombre = '';
  String direccion = '';
  String ciudad = '';
  String codigoPostal = '';
  XFile? fotoEdificioXFile;
  XFile? graficoEdificioXFile;

  // Screen 2
  String otrasIdentificaciones = '';
  String usoPrincipal = '';
  String latitud = '';
  String longitud = '';
  String inspector = '';
  String fecha = '';
  String hora = '';

  // Screen 3
  String pisos = '';
  String area = '';
  String anioConstruccion = '';
  String anioCodigo = '';

  // Screen 4
  bool ampliacionSi = false;
  bool ampliacionNo = false;
  String anioAmpliacion = '';
  String ocupacion = '';
  bool historico = false;

  // Screen 5
  bool albergue = false;
  bool gubernamental = false;
  String unidades = '';
  String tipoSueloSeleccionado = '';
  String comentarios = '';

  void clear() {
    nombre = '';
    direccion = '';
    ciudad = '';
    codigoPostal = '';
    fotoEdificioXFile = null;
    graficoEdificioXFile = null;

    otrasIdentificaciones = '';
    usoPrincipal = '';
    latitud = '';
    longitud = '';
    inspector = '';
    fecha = '';
    hora = '';

    pisos = '';
    area = '';
    anioConstruccion = '';
    anioCodigo = '';

    ampliacionSi = false;
    ampliacionNo = false;
    anioAmpliacion = '';
    ocupacion = '';
    historico = false;

    albergue = false;
    gubernamental = false;
    unidades = '';
    tipoSueloSeleccionado = '';
    comentarios = '';
  }
}
