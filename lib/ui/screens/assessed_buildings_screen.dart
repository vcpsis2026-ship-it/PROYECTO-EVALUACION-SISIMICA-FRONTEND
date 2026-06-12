import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/building_list_service.dart';
import '../../data/models/building_list_response.dart';
import 'profile_admin_screen.dart';
import 'building_pdf_service.dart';

class AssessedBuildingsPage extends StatefulWidget {
  const AssessedBuildingsPage({super.key});

  @override
  State<AssessedBuildingsPage> createState() => _AssessedBuildingsPageState();
}

class _AssessedBuildingsPageState extends State<AssessedBuildingsPage> {
  List<BuildingData> _edificios = [];
  List<BuildingData> _filteredEdificios = [];
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  String? _userId;
  String? _token;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSessionAndData();
  }

  Future<void> _loadSessionAndData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
      _token  = prefs.getString('accessToken');
    });
    await _loadEdificios();
  }

  Future<void> _loadEdificios() async {
    setState(() {
      _isLoading = true;
      _error     = null;
    });
    try {
      final response = await BuildingListService.getBuildings();
      if (response.success && response.buildings != null) {
        setState(() {
          _edificios         = response.buildings!;
          _filteredEdificios = List.from(_edificios);
          _isLoading         = false;
        });
      } else {
        setState(() {
          _error     = response.error ?? 'Error cargando edificios';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error     = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEdificios = query.isEmpty
          ? List.from(_edificios)
          : _edificios
              .where((e) => e.nombreEdificio.toLowerCase().contains(query))
              .toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pop(context); // volver al home
    } else if (index == 1 && _userId != null && _token != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileAdminScreen(userId: _userId, token: _token),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edificios Evaluados'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEdificios,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),   label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor:   AppColors.primary,
        unselectedItemColor: AppColors.gray500,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando edificios...', style: TextStyle(color: AppColors.gray500)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gray500),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadEdificios,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_edificios.isEmpty) {
      return const Center(
        child: Text(
          'No hay edificios registrados',
          style: TextStyle(color: AppColors.gray500),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar edificio por nombre...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filteredEdificios.length} edificio(s)',
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent:  220,
              mainAxisSpacing:      12,
              crossAxisSpacing:     12,
              childAspectRatio:    0.75,
            ),
            itemCount: _filteredEdificios.length,
            itemBuilder: (context, index) {
              final edificio = _filteredEdificios[index];
              return _buildEdificioCard(edificio);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEdificioCard(BuildingData edificio) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Foto del edificio
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: edificio.fotoUrl != null
                  ? Image.network(
                      edificio.fotoUrl!,
                      height: 80,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _EdificioPlaceholder(),
                    )
                  : const _EdificioPlaceholder(),
            ),
            const SizedBox(height: 8),
            // Nombre
            Text(
              edificio.nombreEdificio,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // Dirección (si existe)
            if (edificio.direccion != null) ...[
              const SizedBox(height: 4),
              Text(
                edificio.direccion!,
                style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            // Botón PDF
            ElevatedButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generando reporte PDF...')),
                );
                await BuildingPdfService.generateFullReport(edificio.idEdificio);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('PDF', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _EdificioPlaceholder extends StatelessWidget {
  const _EdificioPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: 100,
      color: Colors.grey.shade200,
      child: const Icon(Icons.apartment, size: 40, color: Colors.grey),
    );
  }
}
