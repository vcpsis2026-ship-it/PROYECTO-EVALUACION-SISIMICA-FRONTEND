import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.user['nombre']?.toString() ?? '');
    _telefonoController = TextEditingController(text: widget.user['telefono']?.toString() ?? '');
    _direccionController = TextEditingController(text: widget.user['direccion']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      if (token.isEmpty) {
        _showError('Token de autenticación no encontrado');
        return;
      }

      final userId = widget.user['id']?.toString();
      if (userId == null) {
        _showError('ID de usuario no válido');
        return;
      }

      final response = await UserService.updateUser(
        token: token,
        userId: userId,
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario actualizado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para recargar
      } else {
        _showError(response.error ?? 'Error al actualizar usuario');
      }
    } catch (e) {
      _showError('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Usuario'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actualizar Datos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        if (value.trim().length < 5) {
                          return 'El nombre debe tener al menos 5 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Teléfono
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length > 10) {
                          return 'El teléfono no debe superar 10 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dirección
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Guardar Cambios',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
